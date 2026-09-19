# Week-114 <!-- omit in toc -->

## 概要

ここは「[Week 114 – Cortex Search](https://frostyfriday.org/)」の Terraform 版解法置き場です。
[sql/week-114.sql](../../sql/week-114.sql) は SQL での解法、こちらは Terraform での解法です。
インフラ部分（schema・stage・table定義・Cortex Search Service）を Terraform で作成します。ドキュメントのアップロードや本文抽出、検証などデータの操作はSQLで手動実行します。

## 目次 <!-- omit in toc -->

- [概要](#概要)
- [フォルダ構成](#フォルダ構成)
- [事前準備](#事前準備)
  - [.env](#env)
  - [parameters](#parameters)
- [Terraformが作るもの / 作らないもの](#terraformが作るもの--作らないもの)
  - [作るもの](#作るもの)
  - [作らないもの（手動SQLで実施）](#作らないもの手動sqlで実施)
- [手順](#手順)
- [後始末](#後始末)

## フォルダ構成

| フォルダ | 内容 |
|:--|:--|
| [modules/journal_search](./modules/journal_search) | 実体（schema・stage・table定義・Cortex Search Service）を定義するTerraformモジュール。dev/stg/prdで共有する想定 |
| [environments/dev](./environments/dev) | dev環境固有の設定。`terragrunt.hcl`が`terraform.source`で上記モジュールを指し、CSVから読んだ値を`inputs`として渡す。今回はdevだけ |
| [environments/dev/parameters/database](./environments/dev/parameters/database) | database/schema/warehouse名などの設定値（csv）|

## 事前準備

### .env

`terraform/.env`（gitignore済み）に、snowflakedb/snowflake provider v2.x が読む環境変数を設定する：

```ini:.env
SNOWFLAKE_ACCOUNT_NAME=...
SNOWFLAKE_ORGANIZATION_NAME=...
SNOWFLAKE_USER=...
```

### parameters

[environments/dev/parameters](./environments/dev/parameters) にあるパラメータを、使用する環境に合わせて設定する

```csv:database_schema.csv
database_name,schema_name,warehouse_name,comment
M_KAJIYA_FROSTY_FRIDAY,SERVICES,M_KAJIYA_FROSTY_FRIDAY_WH,FrostyFriday week-114
```

## Terraformが作るもの / 作らないもの

### 作るもの

- `snowflake_schema.services`：スキーマ SERVICES
- `snowflake_stage_internal.documents`：ディレクトリテーブル有効化・SNOWFLAKE_SSE暗号化のステージ DOCUMENTS_STAGE
- `snowflake_table.documents`：列だけ定義した空テーブル DOCUMENTS（file_name, content）
- `snowflake_table.documents_with_url`：列だけ定義した空テーブル DOCUMENTS_WITH_URL（file_name, content, presigned_url）
- `snowflake_cortex_search_service.journal`：DOCUMENTS_WITH_URL を検索対象にした JOURNAL_SEARCH_SERVICE

### 作らないもの（手動SQLで実施）

- PDFファイルのステージへのアップロード
- `AI_PARSE_DOCUMENT` による本文抽出とDOCUMENTSテーブルへの投入
- `GET_PRESIGNED_URL` によるURL付与とDOCUMENTS_WITH_URLテーブルへの投入
- `AI_COMPLETE` を使った検証クエリ（タイトル抽出）

## 手順

1. `make apply` を実行して Snowflake オブジェクトを作成
2. PDFをステージへアップロードする（Snowflake CLI）。

   ```bash
   snow stage copy "sql/week-114/documents_ja/*.pdf" @M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_stage \
       --overwrite \
       --connection sandbox
   ```

3. ディレクトリテーブルを更新し、DOCUMENTSテーブルへ本文を投入する。

   Terraformが `DOCUMENTS` テーブルを既に作成済みのため、
   [sql/week-114.sql](../../sql/week-114.sql) と同じく CTAS を使うと
   Terraformが管理するテーブルオブジェクトを握り潰してしまう。
   代わりに `INSERT INTO` で実行する。

   ```sql
   use role SYSADMIN;
   use database M_KAJIYA_FROSTY_FRIDAY;
   use schema SERVICES;

   alter stage documents_stage refresh;

   insert into M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents (file_name, content)
   select
       relative_path as file_name,
       AI_PARSE_DOCUMENT(
           TO_FILE('@M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_stage', relative_path),
           {'mode': 'OCR'}
       ):content::varchar as content
   from directory(@M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_stage);
   ```

4. `DOCUMENTS_WITH_URL` テーブルへ事前署名URL付きで投入する。

   `DOCUMENTS_WITH_URL` もTerraformが空テーブルとして作成済み。
   `documents`と同様の理由で、元SQLの CTAS ではなく `INSERT INTO` で実行。

   ```sql
   insert into M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_with_url (file_name, content, presigned_url)
   select
       file_name,
       content,
       get_presigned_url(@M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_stage, file_name) as presigned_url
   from M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents;
   ```

5. Cortex Search Service をリフレッシュする

   Cortex Search Service を作成済み、かつ、更新ラグを1日取っているので、手動でリフレッシュする。

   ```sql
   ALTER CORTEX SEARCH SERVICE M_KAJIYA_FROSTY_FRIDAY.SERVICES.journal_search_service REFRESH;
   ```

6. 検証する。

   ```sql
   with search_result as (
       select
           r.value:file_name::varchar as file_name,
           r.value:content::varchar as content,
           r.value:presigned_url::varchar as presigned_url
       from table(flatten(
           parse_json(
               snowflake.cortex.search_preview(
                   'm_kajiya_frosty_friday.services.journal_search_service',
                   '{
                       "query": "経済学についての論文はどれですか？",
                       "columns": ["file_name", "content", "presigned_url"],
                       "limit": 1
                   }'
               )
           )['results']
       )) r
   )
   select
       file_name,
       snowflake.cortex.ai_complete(
           'llama3.1-8b',
           '次の論文のタイトルを答えて。タイトル以外は出力不要\n\n' || content
       ) as title,
       presigned_url
   from search_result;
   ```

## 後始末

```bash
terragrunt run --all --non-interactive -- destroy
```
