-----------------------------------------------------------------------------------------------
--
-- Week 3 https://frostyfriday.org/blog/2022/07/15/week-3-basic/
-- 

-- In Week 1 we looked at ingesting S3 data, now it’s time to take that a step further. So this week we’ve got a short list of tasks for you all to do.
-- The basics aren’t earth-shattering but might cause you to scratch your head a bit once you start building the solution.
-- Frosty Friday Inc., your benevolent employer, has an S3 bucket that was filled with .csv data dumps. These dumps aren’t very complicated and all have the same style and contents. All of these files should be placed into a single table.
-- However, it might occur that some important data is uploaded as well, these files have a different naming scheme and need to be tracked. We need to have the metadata stored for reference in a separate table. You can recognize these files because of a file inside of the S3 bucket. This file, keywords.csv, contains all of the keywords that mark a file as important.
-- Objective:
-- Create a table that lists all the files in our stage that contain any of the keywords in the keywords.csv file.
-- The S3 bucket’s URI is: s3://frostyfridaychallenges/challenge_3/
-- 

-- 第1週目ではS3データの取り込みを行いましたが、今回はそれを一歩進めていきます。今週は、皆さんに行ってもらう短いタスクリストを用意しました。
-- 基本的な内容ではありますが、実際にソリューションを構築し始めると少し悩むかもしれません。
-- あなたたちの慈悲深い雇用主であるFrosty Friday Inc.は、S3バケットに.csv形式のデータダンプを格納しています。これらのデータはあまり複雑ではなく、すべて同じ形式と内容を持っています。これらすべてのファイルは、1つのテーブルにまとめて格納されるべきです。
-- しかしながら、重要なデータがアップロードされることもあります。これらのファイルは異なる命名規則を持ち、追跡する必要があります。これらのファイルのメタデータは、参照用に別のテーブルに保存する必要があります。これらのファイルが重要であるかどうかは、S3バケット内の keywords.csv というファイルによって判断できます。このファイルには、重要なファイルを特定するためのキーワードがすべて含まれています。

-----------------------------------------------------------------------------------------------

use role SYSADMIN;
use schema M_KAJIYA_FROSTY_FRIDAY.PUBLIC;

set url = 's3://frostyfridaychallenges/challenge_3/';

create or replace temp stage frosty_friday_week3_stage
    url = $url
;

-- ひとまず list する
ls @frosty_friday_week3_stage;

-- いくつか、何か様子のおかしいファイルがありますね

-- どれが重要ファイルなのか、keywords.csv を覗いてみよう
-- cf. ステージングされたファイルのデータのクエリ https://docs.snowflake.com/ja/user-guide/querying-stage

select
    t.$1
    , t.$2
    , t.$3
    , t.$4
    , metadata$filename
from
    @frosty_friday_week3_stage/keywords.csv t
;

-- 中身はわかった
-- ロード用にフォーマットを作る
create or replace temporary file format challenge_3_format
    type = csv
    parse_header = true
;

-- keyword をロード
create or replace temp table challenge_3_keyword
    using template (
        select
            array_agg(object_construct(*))
        from table(
            infer_schema(
                location => '@frosty_friday_week3_stage',
                file_format => 'challenge_3_format',
                files => 'keywords.csv'
            )
        )
    )
;

copy into challenge_3_keyword 
    from
        @frosty_friday_week3_stage
    file_format = (
        type = csv
        skip_header = 1
    )
    -- file_format = challenge_3_format -- では次のエラー： SQL compilation error: Invalid file format "PARSE_HEADER" is only allowed for CSV INFER_SCHEMA and MATCH_BY_COLUMN_NAME
    files = ('keywords.csv')
;

table challenge_3_keyword;


-- keyword 以外のファイル
-- もしかして、問題的にはメタデータだけでいいのでは？ということでこうします。
create or replace temp table challenge_3_dumps (
    filename varchar,
    number_of_rows int
);

copy into challenge_3_dumps 
    from (
        select
            metadata$filename as file_name
            , metadata$file_row_number as number_of_rows
        from
            @frosty_friday_week3_stage
    )
    file_format = (
        type = csv
        skip_header = 1
    )
    pattern = '^(?!.*keyword\.csv).*$' -- keyword.csv 以外
;

table challenge_3_dumps;

-- ファイル名と行数だけにする
with rownum_dumpfiles as (
    select
        filename
        , max(number_of_rows) as number_of_rows
    from
        challenge_3_dumps
    group by
        filename
    order by
        number_of_rows
),
final as (
    select
        rd.filename
        , rd.number_of_rows
    from
        rownum_dumpfiles as rd
    cross join
        challenge_3_keyword as ck
    where
        contains(rd.filename, ck."keyword")
)
select
    * 
from
    final 
order by
    number_of_rows
;

-- FILENAME	NUMBER_OF_ROWS
-- challenge_3/week3_data2_stacy_forgot_to_upload.csv	11
-- challenge_3/week3_data4_extra.csv	12
-- challenge_3/week3_data5_added.csv	13
