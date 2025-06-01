/*

URL: https://frostyfriday.org/blog/2023/07/14/week-54-intermediate/


Not every new feature had a big announcement at Summit 2023, but that doesn’t mean we can’t spotlight it!

This week we’ve got a puzzle for you to crack and without spoiling everything, let’s see if you can figure out the puzzle from the starting code :

<Startup Code>

As you can see, we create 2 simple tables and a new role that can select and insert from these tables. We now wish to use that role to create and execute a stored procedure to move data from table A to table B. HOWEVER, the role that we’ve created doesn’t have the CREATE PROCEDURE privilege!

The challenge for today is to create and execute the following procedure without granting the CREATE PROCEDURE privilege:

<Procedure>

CREATE OR REPLACE copy_to_table(fromTable STRING, toTable STRING, count INT) RETURNS STRING 
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.8'
    PACKAGES = ('snowflake-snowpark-python')
    HANDLER = 'copyBetweenTables'
AS
$$
def copyBetweenTables(snowpark_session, fromTable, toTable, count): 
    snowpark_session.table(fromTable).limit(count).write.mode("append").save_as_table(toTable)
    return "Success"
$$
;

You solution should keep the procedure intact, and this piece of code needs to be part of your solution:

CALL copy_to_table('table_a', 'table_b', 5);

---

すべての新機能が Summit 2023 で大々的に発表されたわけではありませんが、だからといって注目できないわけではありません。

今週は皆さんに解いていただきたいパズルを用意しました。すべてをネタバレすることなく、開始コードからパズルを解けるかどうか見てみましょう。

＜Startup Code＞

ご覧の通り、2つのシンプルなテーブルと、これらのテーブルからSELECTとINSERTを実行できる新しいロールを作成しました。このロールを使用して、テーブルAからテーブルBにデータを移動するストアドプロシージャを作成・実行したいのですが、作成したロールにはCREATE PROCEDURE権限がありません。

今日の課題は、CREATE PROCEDURE 権限を付与せずに次のプロシージャを作成して実行することです。

＜Procedure＞

CREATE OR REPLACE copy_to_table(fromTable STRING, toTable STRING, count INT) RETURNS STRING 
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.8'
    PACKAGES = ('snowflake-snowpark-python')
    HANDLER = 'copyBetweenTables'
AS
$$
def copyBetweenTables(snowpark_session, fromTable, toTable, count): 
    snowpark_session.table(fromTable).limit(count).write.mode("append").save_as_table(toTable)
    return "Success"
$$
;

ソリューションではプロシージャをそのまま維持する必要があり、次のコードをソリューションの一部にする必要があります。

CALL copy_to_table('table_a', 'table_b', 5);

*/

------------------------------------------------------------
-- 
-- 準備
-- Frosty_friday 用に環境を作るよ
-- 
------------------------------------------------------------
 
-- 
-- 所定のスタートアップコード
-- 

-- database and schema creation
use role SYSADMIN; -- 指定が無いので追加
-- いつもの Frosty Friday 用DBを使いたいので、DBだけ変更している
set DB_F_F_WEEK_54 = 'M_KAJIYA_FROSTY_FRIDAY';
CREATE DATABASE IF NOT EXISTS identifier($DB_F_F_WEEK_54);
USE DATABASE identifier($DB_F_F_WEEK_54);
CREATE SCHEMA IF NOT EXISTS WEEK_54;
use schema WEEK_54;

--table creation
CREATE TABLE table_a (
    id INT,
    name VARCHAR,
    age INT
);

CREATE TABLE table_b (
    id INT,
    name VARCHAR,
    age INT
);

--data creation
INSERT INTO table_a (id, name, age)
VALUES
    (1, 'John', 25),
    (2, 'Mary', 30),
    (3, 'David', 28),
    (4, 'Sarah', 35),
    (5, 'Michael', 32),
    (6, 'Emily', 27),
    (7, 'Daniel', 29),
    (8, 'Olivia', 31),
    (9, 'Matthew', 26),
    (10, 'Sophia', 33),
    (11, 'Jacob', 24),
    (12, 'Emma', 29),
    (13, 'Joshua', 32),
    (14, 'Ava', 30),
    (15, 'Andrew', 28),
    (16, 'Isabella', 34),
    (17, 'James', 27),
    (18, 'Mia', 31),
    (19, 'Logan', 25),
    (20, 'Charlotte', 29)
;


--role creation
USE ROLE SECURITYADMIN; -- 指定が無いので追加
CREATE ROLE week_54_role;
GRANT ROLE week_54_role to user <your_user_name>; -- <your_user_name> を自分のユーザ名に置き換えてください

use role SYSADMIN; -- 指定が無いので追加
GRANT USAGE ON database identifier($DB_F_F_WEEK_54)
    TO ROLE week_54_role;
GRANT USAGE ON schema WEEK_54
    TO ROLE week_54_role;
GRANT SELECT ON ALL TABLES IN SCHEMA WEEK_54
    TO ROLE week_54_role;
GRANT INSERT ON ALL TABLES IN SCHEMA WEEK_54
    TO ROLE week_54_role;
GRANT USAGE ON WAREHOUSE M_KAJIYA_WH
    TO ROLE week_54_role;

-- ロールから見えるものの確認
use role week_54_role;
show schemas;
show tables;

-- CREATE PROCEDURE 権限は与えていないので、当然、ストアドプロシージャは作れない
-- 一応、打ってみる
CREATE OR REPLACE PROCEDURE test()
    RETURNS STRING 
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.11'
    PACKAGES = ('snowflake-snowpark-python')
    HANDLER = 'main'
AS
$$
def main(session):
    return 'Week-54'
$$
;

------------------------------------------------------------
-- 
-- 解法1. 
-- 
-- そういえば ストアドプロシージャには 匿名プロシージャというのがありましたね
-- 匿名プロシージャは 2023/06 にGAとなった機能です。この問題が出たのは 2023/07 でした
-- cf. https://docs.snowflake.com/en/release-notes/2023/7_19
-- 
------------------------------------------------------------ 

use role week_54_role;

with copy_to_table as procedure(fromTable STRING, toTable STRING, count INT)
    RETURNS STRING 
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.11'
    PACKAGES = ('snowflake-snowpark-python')
    HANDLER = 'copyBetweenTables'
AS
$$
def copyBetweenTables(snowpark_session, fromTable, toTable, count): 
    snowpark_session.table(fromTable).limit(count).write.mode("append").save_as_table(toTable)
    return "Success"
$$
CALL copy_to_table('table_a', 'table_b', 5);

table table_b;

-- 
-- 解法2. の前にあとしまつ
-- 

truncate table_b;

------------------------------------------------------------
-- 
-- 解法2. 
-- 
-- week_54_role には CREATE PROCEDURE を与えたくないらしいので、
-- ストアドプロシージャを SYSADMIN で作りまして
-- week_54_role に USAGE を与えまして
-- AS CALLER で実行してもらいましょうか
-- 
------------------------------------------------------------ 

use role sysadmin;

CREATE OR REPLACE PROCEDURE copy_to_table(fromTable STRING, toTable STRING, count INT)
    RETURNS STRING 
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.11' -- 3.8 はもうサポートされてません。時の流れは早いもので
    PACKAGES = ('snowflake-snowpark-python')
    HANDLER = 'copyBetweenTables'
    EXECUTE AS CALLER
AS
$$
def copyBetweenTables(snowpark_session, fromTable, toTable, count): 
    snowpark_session.table(fromTable).limit(count).write.mode("append").save_as_table(toTable)
    return "Success"
$$
;

grant usage on procedure M_KAJIYA_FROSTY_FRIDAY.WEEK_54.copy_to_table(string, string, int) 
    to week_54_role;

use role week_54_role;

CALL copy_to_table('table_a', 'table_b', 5);

table table_b;

-- ところで先ほど ストアドプロシージャでのリネージサポートがプレビューになってましたね
-- cf. https://docs.snowflake.com/en/release-notes/2025/other/2025-05-27-lineage

-- revoke usage on procedure M_KAJIYA_FROSTY_FRIDAY.WEEK_54.copy_to_table(string, string, int) from week_54_role;

------------------------------------------------------------
-- 
-- あとしまつ
-- 
------------------------------------------------------------ 

use role SYSADMIN;

------------------------------------------------------------
-- 
-- 参考
-- 
------------------------------------------------------------ 

-- - xxxx
-- - xxxx
-- - xxxx
