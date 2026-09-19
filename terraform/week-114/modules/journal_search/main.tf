# Week-114 (https://frostyfriday.org/) の Cortex Search Service
# ドキュメントのアップロード・AI_PARSE_DOCUMENTでの本文抽出・検証クエリは
# README.md に記載の手動SQLで行う。

resource "snowflake_schema" "services" {
  provider = snowflake.sysadmin

  database = data.snowflake_database.this.name
  name     = var.schema_name
  comment  = var.schema_comment
}

resource "snowflake_stage_internal" "documents" {
  provider = snowflake.sysadmin

  database = snowflake_schema.services.database
  schema   = snowflake_schema.services.name
  name     = "DOCUMENTS_STAGE"
  comment  = "GET_PRESIGNED_URLを使うためディレクトリテーブルを有効化した論文格納ステージ"

  directory {
    enable = true
  }

  encryption {
    snowflake_sse {}
  }
}

resource "snowflake_table" "documents" {
  provider = snowflake.sysadmin

  database = snowflake_schema.services.database
  schema   = snowflake_schema.services.name
  name     = "DOCUMENTS"

  column {
    name = "FILE_NAME"
    type = "VARCHAR"
  }

  column {
    name = "CONTENT"
    type = "VARCHAR"
  }
}

resource "snowflake_table" "documents_with_url" {
  provider = snowflake.sysadmin

  database = snowflake_schema.services.database
  schema   = snowflake_schema.services.name
  name     = "DOCUMENTS_WITH_URL"
  # CREATE TABLE単体のデフォルトはFALSEだが、このテーブルをソースにした
  # snowflake_cortex_search_service作成時にSnowflakeが裏でTRUEへ書き換える
  # （インクリメンタルリフレッシュに必要なため）。明示しないと毎plan差分が出続ける。
  change_tracking = true

  column {
    name = "FILE_NAME"
    type = "VARCHAR"
  }

  column {
    name = "CONTENT"
    type = "VARCHAR"
  }

  column {
    name = "PRESIGNED_URL"
    type = "VARCHAR"
  }
}

resource "snowflake_cortex_search_service" "journal" {
  provider = snowflake.sysadmin

  database        = snowflake_schema.services.database
  schema          = snowflake_schema.services.name
  name            = local.service_name
  on              = "CONTENT"
  attributes      = ["FILE_NAME", "PRESIGNED_URL"]
  warehouse       = var.warehouse_name
  target_lag      = "1 day"
  embedding_model = "voyage-multilingual-2"
  query           = "select content, file_name, presigned_url from ${snowflake_table.documents_with_url.name}"
}
