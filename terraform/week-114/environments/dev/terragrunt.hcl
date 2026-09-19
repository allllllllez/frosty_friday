include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  database_config = csvdecode(file("${get_terragrunt_dir()}/parameters/database/database_schema.csv"))[0]
}

terraform {
  source = "${get_terragrunt_dir()}/../../modules/journal_search"
}

inputs = {
  database_name  = local.database_config.database_name
  schema_name    = local.database_config.schema_name
  schema_comment = local.database_config.comment
  warehouse_name = local.database_config.warehouse_name
}
