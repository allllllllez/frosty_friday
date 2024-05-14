/*
Frosty Friday Consultants has been hired by the University of Frost’s history department;
they want data on monarchs in their data warehouse for analysis.
Your job is to take the JSON file located here, ingest it into the data warehouse, and parse it into a table that looks like this:
Frosty Friday Consultants はフロスト大学の歴史学部に雇われました。
彼らは、分析のためにデータウェアハウスに君主に関するデータを求めています。
あなたの仕事は、ここ↓にあるJSONファイルをデータウェアハウスに取り込み、次のようなテーブルに解析することです：
https://frostyfridaychallenges.s3.eu-west-1.amazonaws.com/challenge_4/Spanish_Monarchs.json

テーブル；
ID INTER_HOUSE_ID ERA HOUSE NAME NICKNAME_1 NICKNAME_2 NICKNAME_3 BIRTH PLACE_OF_BIRTH START_OF_REIGN QUEEN_OR_QUEEN_CONSORT_1 QUEEN_OR_QUEEN_CONSORT_2 QUEEN _OR_QUEEN_CONSORT_3 END_OF_REIGN DURATION DEATH AGE_AT_TIME_OF_DEATH_YEARS PLACE_OF_DEATH BURIAL_PLACE
... 値は省略...

- Separate columns for nicknames and consorts 1 – 3, many will be null.
  ニックネームとコンソート1～3の列は別々で、多くはNULLになります。
- An ID in chronological order (birth).
  年代（birth）順でIDを振る。
- An Inter-House ID in order as they appear in the file.
  Inter-House ID はファイルに表示されている順番。
- There should be 26 rows at the end.
  最後は26行になるはずです。

Hints:

- Make sure you don’t lose any rows along the way.
  途中で行がなくならないように注意すること。
- Be sure to investigate all the outputs and parameters available when transforming JSON.
  JSONを変換する際に利用可能なすべての出力とパラメーターを調べておくこと。
*/

use role SYSADMIN;
use schema M_KAJIYA_FROSTY_FRIDAY.PUBLIC;

-- 分析対象ファイル
set url = 's3://frostyfridaychallenges/challenge_4';
set file_name = 'Spanish_Monarchs.json';


create temp stage if not exists frosty_friday_stage
    url = $url;

ls @frosty_friday_stage;


-- とりあえずクエリすると、JSONが見える
select top 10
    $1::VARCHAR,
from @frosty_friday_stage
;

-- ファイルフォーマットを作成
create or replace temporary file format challenge_4_format
    type = json
    strip_outer_array = true -- 外側の [ ] を削除（いらない）
;

-- とりあえず推定してもらう（実際この構造になっているので安心）
select *
from table(
    infer_schema(
        location=>'@frosty_friday_stage'
        , file_format=>'challenge_4_format'
    )
);

-- COLUMN_NAME	TYPE	NULLABLE	EXPRESSION	FILENAMES	ORDER_ID
-- Era	TEXT	TRUE	$1:Era::TEXT	challenge_4/Spanish_Monarchs.json	0
-- Houses	ARRAY	TRUE	$1:Houses::ARRAY	challenge_4/Spanish_Monarchs.json	1

-- ... じゃあ Era と Houses で flatten しようぜ、となる


-------------------------------------------------------------------------------
-- いくつかの回答パターンを作ってみる
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- 
-- パターン1
-- 
-- CTAS
-- 

-- 一旦テーブルにロードしよう
create or replace temp table challenge_4_load as
select
    $1::variant as value,
from @frosty_friday_stage
(file_format => 'challenge_4_format')
;

table challenge_4_load;

create or replace temp table challenge_4_result as
select
    row_number() over (order by Monarchs.value:"Birth"::date) as ID,
    Monarchs.index + 1 as INTER_HOUSE_ID, -- 配列にある要素のインデックス cf. https://docs.snowflake.com/ja/sql-reference/functions/flatten#output
    c.value:Era::string as ERA,
    houses.value:House::string as House,
    Monarchs.value:"Name"::string as NAME,
    case
        when Monarchs.value:"Nickname"[0]::string is not null then Monarchs.value:"Nickname"[0]::string 
        else Monarchs.value:"Nickname"::string 
    end as NICKNAME_1,
    Monarchs.value:"Nickname"[1]::string as NICKNAME_2,
    Monarchs.value:"Nickname"[2]::string as NICKNAME_3,
    Monarchs.value:"Birth"::string as BIRTH,
    Monarchs.value:"Place of Birth"::string as PLACE_OF_BIRTH,
    Monarchs.value:"Start of Reign"::string as START_OF_REIGN,
    case
        when Monarchs.value:"Consort\/Queen Consort"[0]::string is not null then Monarchs.value:"Consort\/Queen Consort"[0]::string 
        else Monarchs.value:"Consort\/Queen Consort"::string 
    end as QUEEN_OR_QUEEN_CONSORT_1,
    Monarchs.value:"Consort\/Queen Consort"[1]::string as QUEEN_OR_QUEEN_CONSORT_2,
    Monarchs.value:"Consort\/Queen Consort"[2]::string as QUEEN_OR_QUEEN_CONSORT_3,
    Monarchs.value:"End of Reign"::string as END_OF_REIGN,
    Monarchs.value:"Duration"::string as DURATION,
    Monarchs.value:"Death"::string as DEATH,
    Monarchs.value:"Age at Time of Death"::string as AGE_AT_TIME_OF_DEATH_YEARS,
    Monarchs.value:"Place of Death"::string as PLACE_OF_DEATH,
    Monarchs.value:"Burial Place"::string as BURIAL_PLACE,
from
    challenge_4_load as c,
    lateral flatten (input => c.value:"Houses") houses,
    lateral flatten (input => houses.value:"Monarchs") Monarchs
order by
    ID;

table challenge_4_result;


-------------------------------------------------------------------------------------------
-- 
-- パターン2
-- 
-- COPY INTO（＋INCLUDE_METADATA オプション） パターン
-- 

create or replace temp table challenge_4_load
    using template (
        select
            array_cat(
                array_agg(object_construct(*)),
                -- cf. https://qiita.com/friedaji/items/9d25cfb071de5792f0d1
                [
                    -- FILE_NAMEカラム
                    {
                        'COLUMN_NAME': 'FILE_NAME',
                        'filenames': '',
                        'NULLABLE': true,
                        'TYPE': 'text'
                    },
                    -- ROW_NUMBERカラム
                    {
                        'COLUMN_NAME': 'ROW_NUMBER',
                        'filenames': '',
                        'NULLABLE': true,
                        'TYPE': 'number'
                    }
                ]::VARIANT
            )
        from
            table(
            infer_schema(
                location=>'@frosty_friday_stage'
                , file_format=>'challenge_4_format'
            )
        )
    )
;

table challenge_4_load;

-- COPY INTO（＋INCLUDE_METADATA オプション）
copy into
    challenge_4_load
from
    @frosty_friday_stage
match_by_column_name = case_sensitive
file_format = (
    format_name = 'challenge_4_format'
)
-- cf. https://docs.snowflake.com/en/release-notes/2024/8_17#new-copy-option-include-metadata
include_metadata = (
    row_number = metadata$file_row_number,
    file_name = METADATA$FILENAME
);

table challenge_4_load;

-- あとは パターン1 と同じ
create or replace temp table challenge_4_result as
select
    row_number() over (order by Monarchs.value:"Birth"::date) as ID,
    Monarchs.index + 1 as INTER_HOUSE_ID, -- 配列にある要素のインデックス cf. https://docs.snowflake.com/ja/sql-reference/functions/flatten#output
    c."Era"::string as ERA,
    houses.value:House::string as House,
    Monarchs.value:"Name"::string as NAME,
    case
        when Monarchs.value:"Nickname"[0]::string is not null then Monarchs.value:"Nickname"[0]::string 
        else Monarchs.value:"Nickname"::string 
    end as NICKNAME_1,
    Monarchs.value:"Nickname"[1]::string as NICKNAME_2,
    Monarchs.value:"Nickname"[2]::string as NICKNAME_3,
    Monarchs.value:"Birth"::string as BIRTH,
    Monarchs.value:"Place of Birth"::string as PLACE_OF_BIRTH,
    Monarchs.value:"Start of Reign"::string as START_OF_REIGN,
    case
        when Monarchs.value:"Consort\/Queen Consort"[0]::string is not null then Monarchs.value:"Consort\/Queen Consort"[0]::string 
        else Monarchs.value:"Consort\/Queen Consort"::string 
    end as QUEEN_OR_QUEEN_CONSORT_1,
    Monarchs.value:"Consort\/Queen Consort"[1]::string as QUEEN_OR_QUEEN_CONSORT_2,
    Monarchs.value:"Consort\/Queen Consort"[2]::string as QUEEN_OR_QUEEN_CONSORT_3,
    Monarchs.value:"End of Reign"::string as END_OF_REIGN,
    Monarchs.value:"Duration"::string as DURATION,
    Monarchs.value:"Death"::string as DEATH,
    Monarchs.value:"Age at Time of Death"::string as AGE_AT_TIME_OF_DEATH_YEARS,
    Monarchs.value:"Place of Death"::string as PLACE_OF_DEATH,
    Monarchs.value:"Burial Place"::string as BURIAL_PLACE,
from
    challenge_4_load as c,
    lateral flatten (input => c."Houses") houses,
    lateral flatten (input => Houses.value:"Monarchs") Monarchs
order by
    ID;

table challenge_4_result;

-------------------------------------------------------------------------------------------
-- 
-- パターン3
-- Snowpark で処理する
-- 

with load_json_in_stage as procedure (
        file_path string,
        table_name string,
        table_type string)
    returns VARCHAR
    language python
    runtime_version = '3.11'
    packages = ('snowflake-snowpark-python==1.14.0')
    handler = 'main'
as 
$$
import snowflake.snowpark as snowpark
from snowflake.snowpark.functions import table_function, row_number
from snowflake.snowpark.functions import col, sql_expr, when
from snowflake.snowpark.window import Window


flatten = table_function('flatten')

def main(session, file_path, table_name, table_type):
    df = session.read.options({
        'strip_outer_array': True
    }).json(file_path)

    # lateral flatten と同じ
    df_flatten = df.select(
        col('$1').alias('C'),
        sql_expr('C:Houses').alias('HOUSES'),
    ).join_table_function(
        'flatten',
        col('HOUSES')
    ).select(
        col('C'),
        sql_expr('VALUE:House').alias('HOUSE'),
        sql_expr('VALUE:Monarchs').alias('MONARCHS'),
    ).join_table_function(
        'flatten',
        col('MONARCHS')
    ).select(
        col('C'),
        col('HOUSE'),
        col('VALUE').alias('MONARCHS'),
        col('INDEX')
    )

    df_result = df_flatten.select(
        row_number().over(Window.order_by(sql_expr('Monarchs:"Birth"'))).alias('ID'),
        (col('INDEX') + 1).alias('INTER_HOUSE_ID'),  #  配列にある要素のインデックス cf. https://docs.snowflake.com/ja/sql-reference/functions/flatten#output
        sql_expr('C:Era').alias('ERA'),
        col('HOUSE').alias('HOUSE'),
        sql_expr('MONARCHS:Name').alias('Name'),
        when(
            sql_expr('MONARCHS:Nickname[0]').is_not_null(), sql_expr('MONARCHS:Nickname[0]')
        ).otherwise(
            sql_expr('MONARCHS:Nickname')
        ).alias('NICKNAME_1'),
        sql_expr('MONARCHS:Nickname[1]').alias('NICKNAME_2'),
        sql_expr('MONARCHS:Nickname[2]').alias('NICKNAME_3'),
        sql_expr('MONARCHS:Birth').alias('BIRTH'),
        sql_expr('MONARCHS:"Place of Birth"').alias('PLACE_OF_BIRTH'),
        sql_expr('MONARCHS:"Start of Reign"').alias('START_OF_REIGN'),
        when(
            sql_expr('MONARCHS:"Consort\/Queen Consort"[0]').is_not_null(), sql_expr('MONARCHS:"Consort\/Queen Consort"[0]')
        ).otherwise(
            sql_expr('MONARCHS:"Consort\/Queen Consort"')
        ).alias('QUEEN_OR_QUEEN_CONSORT_1'),
        sql_expr('MONARCHS:"Consort\/Queen Consort"[1]').alias('QUEEN_OR_QUEEN_CONSORT_2'),
        sql_expr('MONARCHS:"Consort\/Queen Consort"[2]').alias('QUEEN_OR_QUEEN_CONSORT_3'),
        sql_expr('MONARCHS:"End of Reign"').alias('END_OF_REIGN'),
        sql_expr('MONARCHS:Duration').alias('DURATION'),
        sql_expr('MONARCHS:Death').alias('DEATH'),
        sql_expr('MONARCHS:"Age at Time of Death"').alias('AGE_AT_TIME_OF_DEATH_YEARS'),
        sql_expr('MONARCHS:"Place of Death"').alias('PLACE_OF_DEATH'),
        sql_expr('MONARCHS:"Burial Place"').alias('BURIAL_PLACE'),
    )

    df_result.write.mode('overwrite').save_as_table(table_name=table_name, table_type=table_type)
    return 'Succeeded'

if __name__ == "__main__":
    main()

$$
call load_json_in_stage(
    file_path=>'@frosty_friday_stage/' || $file_name, -- '@<stage_name>/<file_path>'
    table_name=>'challenge_4_result',
    table_type=>'temporary'
)
;

table challenge_4_result;
