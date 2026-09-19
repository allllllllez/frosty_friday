output "documents_stage_name" {
  description = "ドキュメント格納用ステージの完全修飾名"
  value       = "${snowflake_schema.services.database}.${snowflake_schema.services.name}.${snowflake_stage_internal.documents.name}"
}

output "documents_with_url_table_name" {
  description = "事前署名URL付きテーブルの完全修飾名"
  value       = "${snowflake_schema.services.database}.${snowflake_schema.services.name}.${snowflake_table.documents_with_url.name}"
}

output "journal_search_service_name" {
  description = "作成したCortex Search Serviceの完全修飾名"
  value       = "${snowflake_schema.services.database}.${snowflake_schema.services.name}.${snowflake_cortex_search_service.journal.name}"
}
