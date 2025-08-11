# frosty_fryday challenge

[frosty_fryday()](https://frostyfriday.org/) を解いてみるチャレンジです。

# 構成

|フォルダ名|説明|
| :- | :- |
|sql|解答クエリ|
|script|クエリ実行用スクリプト|
|log|クエリ実行ログ|
|terraform|解答 Terraform コード|
|python|解答 Python コード|
|image|画像（解答補足など）|

# 実行環境
## on VSCode
VSCode + Snowflake Extention で実行することを想定しています

## on SnowSQL
SnowSQL で実行する仕組みもあります。
[./script/run_snowsql.sh](./script/run_snowsql.sh)を使用します

```bash-session
$ bash ./script/run_snowsql.sh <sql_file> 
```

<details>
<summary>実行例</summary>

```bash-session
❯ bash ./script/run_snowsql.sh ./sql/test.sql 
* SnowSQL * v1.2.32
Type SQL statements or !help
-------------------------------------------------------------------------------- 
-- 
-- testだよ
-- 
-------------------------------------------------------------------------------- 
 
use role SYSADMIN;
+----------------------------------+
| status                           |
|----------------------------------|
| Statement executed successfully. |
+----------------------------------+
1 Row(s) produced. Time Elapsed: 0.080s
use warehouse M_KAJIYA_WH;
+----------------------------------+
| status                           |
|----------------------------------|
| Statement executed successfully. |
+----------------------------------+
1 Row(s) produced. Time Elapsed: 0.113s
select 'FROSTY_FRIDAY';
+-----------------+
| 'FROSTY_FRIDAY' |
|-----------------|
| FROSTY_FRIDAY   |
+-----------------+
1 Row(s) produced. Time Elapsed: 0.085s
```

</details>
