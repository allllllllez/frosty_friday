/*
If you know your SnowPro factoids, you’d know that when you CLONE an object, you can only replicate the grants on that object if that object is a table. But wouldn’t life be easier if that wasn’t the case? Well…make it so!

Your challenge is to create a stored procedure that not only creates a clone of a schema, but replicates all the grants on that schema. This should be able to accept a custom ‘AT’ or ‘BEFORE’ statement written by the user.

Pay attention to the parameters being passed into the function:

- database_name = this should be the name of the database of the original schema
- schema_name = this should be the name of the original schema
- target_database = this should be the database of the cloned schema
- cloned_schema_name = this should be the cloned schema’s name
- at_or_before_statement = your user should be able to provide a custom AT/BEFORE statement which will be appended to the CREATE …. CLONE statement. E.g:
    - ‘at (timestamp => to_timestamp_tz(’04/05/2013 01:02:03’, ‘mm/dd/yyyy hh24:mi:ss’));’
     - ‘before (statement => ‘8e5d0ca9-005e-44e6-b858-a8f5b37c5726′);’

 With the last parameter, the code above passes a NULL. Bonus points for those who test that this part of their code is working!

---

SnowPro のちょっとした知識をご存知であれば、オブジェクトをCLONEする場合、そのオブジェクトがテーブルである場合にのみ、そのオブジェクトに付与された権限を複製できることをご存知でしょう（※）。
しかし、もしそうでなければ、人生はもっと楽になるのではないでしょうか？では、そうしましょう！
（※） データベースやスキーマに付与していた権限はコピーされない。さらに
       https://docs.snowflake.com/ja/user-guide/object-clone#access-control-privileges-for-cloned-objects
       > ソースオブジェクトがデータベースまたはスキーマである場合、クローンは、ソースオブジェクト含まれている子オブジェクトのクローンに対して付与された すべて の権限を継承します。
       > コンテナ自体 (データベースまたはスキーマ) のクローンには、ソース コンテナに付与された権限が継承されないことに注意してください。
       https://docs.snowflake.com/ja/sql-reference/sql/create-clone#general-usage-notes
       > CREATE TABLE ... CLONE と CREATE EVENT TABLE ... CLONE 構文には、次のように新しいテーブルクローンに影響する COPY GRANTS キーワードが含まれています。

あなたの課題は、スキーマのクローンを作成するだけでなく、そのスキーマ上のすべての権限付与を複製するストアドプロシージャを作成することです。
このストアドでは、'AT' または 'BEFORE' 指定を受け入れ可能でなければなりません。

関数に渡されるパラメータに注意してください：

- database_name = 元のスキーマのデータベース名。
- schema_name = 元のスキーマ名。
- target_database = 複製スキーマのデータベース名。
- cloned_schema_name = 複製スキーマ名。
- at_or_before_statement = CREATE ... CLONE 文に追加する AT/BEFORE を指定する。
  次のように CLONE 文に AT/BEFORE を付加する：
    - 'at (timestamp => to_timestamp_tz('04/05/2013 01:02:03', 'mm/dd/yyyy hh24:mi:ss'));'.
    - 'before (statement => '8e5d0ca9-005e-44e6-b858-a8f5b37c5726′);'.

最後のパラメータで、上のコードはNULLを渡します。ここまでテストした人にはボーナス・ポイントをあげましょう！

*/

------------------------------------------------------------
-- 
-- 初期設定（利用ロール設定を追加しています）
-- 
------------------------------------------------------------ 
use role SECURITYADMIN;
create or replace role frosty_role_one;
create or replace role frosty_role_two;
create or replace role frosty_role_three;

use role SYSADMIN;
use database M_KAJIYA_FROSTY_FRIDAY;
create or replace schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema;
create or replace table M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema.table_one (key int, value varchar);

use schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema;
grant all on schema cold_lonely_schema to frosty_role_one;
grant all on schema cold_lonely_schema to frosty_role_two;
grant all on schema cold_lonely_schema to frosty_role_three;

grant all on table cold_lonely_schema.table_one to frosty_role_one;
grant all on table cold_lonely_schema.table_one to frosty_role_two;
grant all on table cold_lonely_schema.table_one to frosty_role_three;


-- お題を解く前に、ふつうにクローンしたときの権限を確認してみよう
-- スキーマ、テーブルとも3つのロールに対して grant all しているので、全権限が付与されているのがわかる
show grants on schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema;
show grants on table M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema.table_one;

-- ふつうにクローンする...
create schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone
    clone M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema;

-- クローン先の権限を確認してみよう
-- スキーマに対する権限はコピーされていない様子がわかる
show grants on schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone;
show grants on table M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone.table_one;


-- 回答編に入る前に、クローン先を削除しておく
drop schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone;

-------------------------------------------------------------------------------
-- 
-- 回答編
-- 
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- 
-- パターン1 
-- 
-- スキーマの権限をコピーする
-- 
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- 
-- パターン2
-- 
-- INFORMATION_SCHEMA.OBJECT_PRIVILEGES
-- 
-------------------------------------------------------------------------------
create or replace procedure M_KAJIYA_FROSTY_FRIDAY.PUBLIC.schema_clone_with_copy_grants(
    database_name string, 
    schema_name string, 
    target_database string, 
    cloned_schema_name string, 
    at_or_before_statement string
)
  returns varchar
--   returns table()
  language python
  runtime_version = '3.11'
  packages = ('snowflake-snowpark-python==1.20.0')
  handler = 'main'
  comment = 'データベース・テーブルに付与された権限も含めてクローンする'
  execute as owner
  as
$$
import snowflake.snowpark as snowpark
from snowflake.snowpark.functions import col
from snowflake.snowpark.exceptions import SnowparkSQLException

def get_error_msg(details: str, excepion: Exception) -> dict:
    '''エラー発生時にストアドプロシージャが返すメッセージを作成'''
    return {
        'STATUS': 'Error',
        'DETAILS': details,
        'EXCEPTION': excepion
    }
def copy_table_with_grant(
        session: snowpark.Session,
        src_db: str,
        src_schema: str,
        dst_db: str,
        dst_schema: str,
        at_or_before_statement='') -> str:
    '''データベース・スキーマに付与された権限も含めてコピーを行う
    
    Parameters
    ----------
    session: snowpark.Session
        Snoflake セッション
    src_db: str
        コピー元データベース
    src_schema: str
        コピー元スキーマ
    dst_db: str
        コピー先データベース
    dst_schema: str
        コピー先スキーマ
    at_or_before_statement : str, optional
        CREATE ... CLONE 文に追加する AT/BEFORE を指定する。デフォルトは空文字

    Returns
    -------
    str
        messages
    '''

    try:
        session.sql(
            f'''
                create schema {dst_db}.{dst_schema} 
                    clone {src_db}.{src_schema}
                    {(at_or_before_statement or "")}
            '''
        ).collect()
    except Exception as e:
        return get_error_msg(
            f'Failed to create schema clone from `{src_db}.{src_schema}` to `{dst_db}.{dst_schema}`',
            e
        )

    # データベース名、スキーマ名を解決
    src_schema_info = session.sql(
        f"show schemas like '{src_schema}' in database {src_db}").collect()[0].as_dict()
    src_db = src_schema_info["database_name"]
    src_schema = src_schema_info["name"]
    print(f'src schema: {src_db}.{src_schema}')

    dst_schema_info = session.sql(
        f"show schemas like '{dst_schema}' in database {dst_db}").collect()[0].as_dict()
    dst_db = dst_schema_info["database_name"]
    dst_schema = dst_schema_info["name"]
    print(f'dst schema: {dst_db}.{dst_schema}')

    # 対象オブジェクトに付与されている権限を取得
    src_objs = session.sql(
        f'''
            select
                *
            from
                {src_db}.INFORMATION_SCHEMA.OBJECT_PRIVILEGES
            {(at_or_before_statement or "")}
        '''
    ).filter(
        (col('OBJECT_CATALOG') == src_db)
        & (
            (col('OBJECT_NAME') == src_schema) | (col('OBJECT_SCHEMA') == src_schema) # クローン元データベース・スキーマ自身が対象。他はスキップ
        )
    )

    for row in src_objs.to_local_iterator():
        try:
            # 権限付与
            # with grant option （権限を自身以外のロールに付与できる）が有効なとき IS_GRANTABLE = YES になっている
            is_grantable = 'WITH GRANT OPTION' if (row["IS_GRANTABLE"]=="YES") else ''
            # スキーマオブジェクトかスキーマかで on ... を書き分ける
            on_clause = f'on {row["OBJECT_TYPE"]} {dst_db}.{dst_schema}' \
                if (row["OBJECT_TYPE"] == "SCHEMA") else f'on {row["OBJECT_TYPE"]} {dst_db}.{dst_schema}.{row["OBJECT_NAME"]}'
            query = f'''
                grant {row["PRIVILEGE_TYPE"]} 
                    {on_clause}
                    to role {row["GRANTEE"]}
                    {is_grantable}
                ;
            '''
            print(query)
            session.sql(query).collect()

        # GRANT でのエラーは無視、ログに出すだけ
        except Exception as e:
            print(
                get_error_msg(
                    f'Ignore error: grant privilege {on_clause}',
                    e
                )
            )
            pass

    return f'{dst_db}.{dst_schema} succesfully cloned from {src_db}.{src_schema}'

def main(
        session: snowpark.Session,
        database_name: str,
        schema_name: str,
        target_database: str,
        cloned_schema_name: str,
        at_or_before_statement: str) -> str:
    return copy_table_with_grant(
        session=session,
        src_db=database_name,
        src_schema=schema_name,
        dst_db=target_database,
        dst_schema=cloned_schema_name,
        at_or_before_statement=at_or_before_statement)

$$
;

-- クローン先を削除しておく
drop schema if exists M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone;

-- 実行してみよう！
call M_KAJIYA_FROSTY_FRIDAY.PUBLIC.schema_clone_with_copy_grants(
    database_name=>'M_KAJIYA_FROSTY_FRIDAY',
    schema_name=>'cold_lonely_schema',
    target_database=>'M_KAJIYA_FROSTY_FRIDAY',
    cloned_schema_name=>'cold_lonely_clone', 
    at_or_before_statement=>NULL
);

-- 履歴を確認してみよう ※VSCode上で実行すると履歴が見えないかも
select *
from table(information_schema.query_history_by_session())
order by start_time desc;

-- クローン先の権限を確認してみよう
show grants on schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone;
-- テーブルは変わらないので特に確認しなくてよし
-- show grants on table M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone.table_one;


-- 
-- テーブル以外のオブジェクト
-- 
-- ためしにtask
CREATE TASK M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema.cold_lonely_task
  SCHEDULE = 'USING CRON 0 0 1 * * Asia/Tokyo'
  AS
    SELECT CURRENT_TIMESTAMP;

grant all on task M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema.cold_lonely_task to frosty_role_one;

show grants on task M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema.cold_lonely_task;

-- ふつうにクローンする...
create or replace schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone
    clone M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema;

-- クローン先の権限を確認してみよう
-- スキーマに対する権限はコピーされていない様子がわかる
show grants on schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone;
show grants on task M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema.cold_lonely_task;
show grants on table M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone.table_one;


-- 
-- at_or_before_statement オプションを試しましょう
-- 
create or replace table cold_lonely_schema.table_two (key int, value varchar);
grant all on table cold_lonely_schema.table_two to frosty_role_two;

-- クローン先を削除
drop schema if exists M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone;

-- クローンする
call M_KAJIYA_FROSTY_FRIDAY.PUBLIC.schema_clone_with_copy_grants(
    database_name=>'M_KAJIYA_FROSTY_FRIDAY', 
    schema_name=>'cold_lonely_schema',
    target_database=>'M_KAJIYA_FROSTY_FRIDAY',
    cloned_schema_name=>'cold_lonely_clone', 
    -- at_or_before_statement=>'at (timestamp => to_timestamp_tz(''2024/08/16 17:00:00'', ''yyyy/mm/dd hh24:mi:ss''))'
    at_or_before_statement=>'at (offset => -60*5)'
);

-- 中身を見てみよう。TABLE_ONE のみならOK
show tables in schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone;


------------------------------------------------------------
-- 
-- 解説のコーナー
-- 
------------------------------------------------------------

-- https://docs.snowflake.com/ja/sql-reference/info-schema/object_privileges
-- すべてのオブジェクトに付与されたアクセス権を一覧できるビューがあります
select
    PRIVILEGE_TYPE
    , OBJECT_TYPE
    , OBJECT_NAME
    , GRANTEE
    , IS_GRANTABLE
    , *
from
    M_KAJIYA_FROSTY_FRIDAY.INFORMATION_SCHEMA.OBJECT_PRIVILEGES
where
    OBJECT_CATALOG = 'M_KAJIYA_FROSTY_FRIDAY'
    -- and IS_GRANTABLE = 'YES'
    and IS_GRANTABLE = 'NO'
;
-- このビューにあるレコードに対して
-- スキーマ自身（OBJECT_TYPE==SCHEMA かつ OBJECT_NAME==コピー先スキーマ名）には
--     grant <PRIVILEGE_TYPE> on <OBJECT_TYPE> dst_database.dst_schema to role <GRANTEE> (IS_GRANTABLE=YES のとき WITH GRANT OPTION )
-- スキーマ配下のオブジェクト（OBJECT_SCHEMA==コピー元スキーマ）には
--     grant <PRIVILEGE_TYPE> on <OBJECT_TYPE> dst_database.dst_schema.<OBJECT_NAME> to role <GRANTEE> (IS_GRANTABLE=YES のとき WITH GRANT OPTION )
-- すれば良さそう、となります

-- なお、ビューなので AT|BEFORE は効きません（指定できるけど意味がない）
-- しかたがないので、エラーを無視します（確実なのはは存在チェックだけど、全部やってると遅い）

------------------------------------------------------------
-- 
-- あとしまつ
-- 
------------------------------------------------------------ 

delete schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_schema;
delete schema M_KAJIYA_FROSTY_FRIDAY.cold_lonely_clone;

use role SECURITYADMIN;
delete role frosty_role_one;
delete role frosty_role_two;
delete role frosty_role_three;
