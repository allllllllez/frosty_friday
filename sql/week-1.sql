-------------------------------------------------------------------------------- 
-- 
-- Week 1
-- 
-- FrostyFriday Inc., your benevolent employer, has an S3 bucket that is filled with .csv data dumps. This data is needed for analysis. Your task is to create an external stage, and load the csv files directly from that stage into a table.
-- あなたの優しい雇用主 FrostyFriday Inc. は、csv にダンプしたデータが詰まったS3バケットを持っています。 
-- これは分析に必要なデータです。
-- あなたの仕事は、外部ステージを作成し、そのステージからcsvファイルをテーブルに直接ロードすることです。
--
-- The S3 bucket’s URI is: s3://frostyfridaychallenges/challenge_1/
-- 
-- Remember if you want to participate:
-- 
-- Sign up as a member of Frosty Friday. You can do this by clicking on the sidebar, and then going to ‘REGISTER‘ (note joining our mailing list does not give you a Frosty Friday account)
-- Post your code to GitHub and make it publicly available (Check out our guide if you don’t know how to here)
-- Post the URL in the comments of the challenge.
-- If you have any technical questions you’d like to pose to the community, you can ask here on our dedicated thread.
-------------------------------------------------------------------------------- 

use role SYSADMIN;
use schema M_KAJIYA_FROSTY_FRIDAY.PUBLIC;


set url = 's3://frostyfridaychallenges/challenge_1/';

create temp stage if not exists frosty_friday_stage
    url = $url;

ls @frosty_friday_stage;

/*
name	size	md5	last_modified
s3://frostyfridaychallenges/challenge_1/1.csv	23	70e8579de8004dd6e8fd269af0231924	Fri, 17 Feb 2023 17:52:39 GMT
s3://frostyfridaychallenges/challenge_1/2.csv	10	e8a01933feaebcfa84076d625b92a533	Fri, 17 Feb 2023 17:52:39 GMT
s3://frostyfridaychallenges/challenge_1/3.csv	49	d275af77c97adf8a6886f2ab68449cf3	Fri, 17 Feb 2023 17:52:38 GMT
*/

-- Note: ステージを作った後はこういう覗き方もできる
with cat_files_in_stage as procedure (stage_name varchar, file_path varchar, max_rows int)
    returns table()
    language python
    runtime_version = '3.11'
    packages = ('snowflake-snowpark-python==1.14.0')
    handler = 'main'
as $$
import snowflake.snowpark as snowpark
from snowflake.snowpark.files import SnowflakeFile

def main(
        session: snowpark.Session,
        stage_name: str,
        file_path: str,
        max_rows: int):
    '''ステージにあるファイルの中身を表示する。テキストファイル用
    cf. https://qiita.com/friedaji/items/130b17f4a1e1157f405d

    Parameters
    ----------
    session : snowpark.Session
        セッション
    stage_name : str
        対象ステージ名。ダブルクォートが必要な時は '"ダブルクォートで囲まれたステージ名"' を指定
    file_path : str
        対象のファイルパス。ステージ名からの相対パスを指定
    max_rows : int
        表示する行数

    Returns
    -------
    _type_
        _description_
    '''        
    df = session.sql(f"select BUILD_SCOPED_FILE_URL(@{stage_name}, '{file_path}')")
    file_list = df.toPandas().values.tolist()
    line_count = max_rows
    re = []
    with SnowflakeFile.open(file_list[0][0]) as f:
        for i,line in enumerate(f):
            if i > line_count:
                break
            re.append(line.strip())

    rd = session.create_dataframe(re)
    return (rd)
$$
call cat_files_in_stage(
    stage_name=>'"FROSTY_FRIDAY_STAGE"',
    file_path=>'1.csv',
    max_rows=>5)
;

/*
'1.csv' の中身:
result
you
have
gotten

'2.csv' の中身：
result
it

'3.csv' の中身：
result
right
NULL
totally_empty
congratulations!
*/

-------------------------------------------------------------------------------
-- いくつかの回答パターンを作ってみる
-------------------------------------------------------------------------------

-- 
-- パターン1 COPY INTO
-- 
-- 便利なところ：
--     - ロード時にフォーマット指定するので file format 不要
--     - ステージのファイルに付与されたメタデータを取得できる
-- 便利じゃないところ：
--     - 先にテーブルを作成する必要がある
--     - whereや集計関数が使えないので、csvの形そのままテーブル化するしかない
-- 

create or replace temp table challenge_1_result (
    result varchar,
    file_name varchar,
    row_number int
);

copy into challenge_1_result 
    from (
        select
            $1::varchar as result,
            metadata$filename,
            metadata$file_row_number
        from
            @frosty_friday_stage
    )
    file_format = (
        type = csv
        skip_header = 1
        null_if = ('NULL')
    )
;

select
    listagg(result, ' ') within group (order by file_name, row_number) as result
from
    challenge_1_result
where
    result is not null
    and result != 'totally_empty'
;
-- RESULT
-- you have gotten it right congratulations!

------------------------------------------------
-- 
-- パターン2 CTAS
-- 
-- 便利なところ：
--     - テーブル作成不要
--     - where でのフィルタリング、集計関数での変形を挟むことができる
--     - ステージのファイルに付与されたメタデータを取得できる
-- 便利じゃないところ
--     - 先に file format を作る必要がある
-- 

create temp file format challenge_1_format
    type = csv
    skip_header = 1
    null_if = ('NULL')
;

create or replace temp table challenge_1_result as
select
    $1::VARCHAR as result,
    metadata$filename as file_name,
    metadata$file_row_number as row_number
from @frosty_friday_stage
(file_format => 'challenge_1_format')
;

select
    listagg(result, ' ') within group (order by file_name, row_number) as result
from
    challenge_1_result
where
    result is not null
    and result != 'totally_empty'
;

-- RESULT
-- you have gotten it right congratulations!

-- 一気に文字列結合することもできる
create or replace temp table challenge_1_result as
-- まずは抽出。やってることは パターン1 と同じ
with src as (
    select
        $1::VARCHAR as result,
        metadata$filename as file_name,
        metadata$file_row_number as row_number
    from @frosty_friday_stage
    (file_format => 'challenge_1_format')
)
-- ここで文字列結合してしまう
select
    listagg(result, ' ') within group (order by file_name, row_number) as result
from
    src
where
    result is not null
    and result != 'totally_empty'
;

table challenge_1_result;

-- RESULT
-- you have gotten it right congratulations!

------------------------------------------------
-- 
-- パターン3 infar_schema
-- 
-- 便利なところ：
--     - テーブル作成時、自分でカラムと方を指定しなくてよい（だけど、便利じゃなさとも言えて悩ましい）
-- 便利じゃないところ：
--     - file formatを作る必要がある
--     - ファイルにないカラムを追加するには alter table が必要
-- 

create or replace temporary file format challenge_1_format
    type = csv
    parse_header = true
    null_if = ('NULL')
;

create or replace temp table challenge_1_result
    using template (
        select
            array_agg(object_construct(*))
        from table(
            infer_schema(
                location=>'@frosty_friday_stage',
                file_format=>'challenge_1_format'
            )
        )
    )
;

desc table challenge_1_result;

copy into challenge_1_result 
    from (
        select
            $1::varchar as result
        from
            @frosty_friday_stage
    )
    file_format = (
        type = csv
        skip_header = 1
        null_if = ('NULL')
    )
;

table challenge_1_result;

select listagg("result", ' ') as result
from challenge_1_result
where "result" is not null and "result" != 'totally_empty'
;

-- insert の順序は不定。たまーに結合結果の文章がおかしいはず。。。ログ参照
