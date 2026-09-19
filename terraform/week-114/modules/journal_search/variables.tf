variable "database_name" {
  type        = string
  description = "対象のSnowflakeデータベース名（data \"snowflake_database\" の検索キーに使用）"
}

variable "env" {
  type        = string
  description = "環境名 dev/stg/prd（env.hclのinputsから渡される。未使用だが、root.hclのinputs mergeにより必須）"
}

variable "infra_name" {
  type        = string
  description = "インフラ名（root.hclのinputsから渡される。未使用だが、root.hclのinputs mergeにより必須）"
}

variable "schema_comment" {
  type        = string
  description = "作成するスキーマのコメント"
}

variable "schema_name" {
  type        = string
  description = "作成するスキーマ名"
}

variable "snowflake_provider_version" {
  type        = string
  description = "Snowflake Providerバージョン（provider.tf生成にのみ使用。未使用だが、root.hclのinputs mergeにより必須）"
}

variable "system_name" {
  type        = string
  description = "システム名（root.hclのinputsから渡される。未使用だが、root.hclのinputs mergeにより必須）"
}

variable "warehouse_name" {
  type        = string
  description = "Cortex Search Serviceが使用するウェアハウス名"
}
