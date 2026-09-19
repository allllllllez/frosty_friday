locals {
  system_name = "kajiya"  # システム名
  infra_name  = "week114" # インフラ名
  environment_vars = read_terragrunt_config(
    # https://github.com/gruntwork-io/terragrunt/issues/1210
    find_in_parent_folders("env.hcl", "fallback.hcl"),
    {
      locals = {
        env                        = "dev",
        snowflake_provider_version = "2.20.0"
      }
    }
  )
}

inputs = merge(
  {
    system_name = local.system_name
    infra_name  = local.infra_name
  },
  local.environment_vars.locals,
)

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
  terraform {
    required_providers {
      snowflake = {
        source  = "snowflakedb/snowflake"
        version = "~> ${local.environment_vars.locals.snowflake_provider_version}"
        configuration_aliases = [
          snowflake.accountadmin,
          snowflake.securityadmin,
          snowflake.sysadmin,
        ]
      }
    }
  }

  // Snowflake Provider
  // NOTE: preview feature は2026年9月17日時点のステータス
  provider "snowflake" {
    alias                    = "accountadmin"
    role                     = "ACCOUNTADMIN"
    authenticator            = "SNOWFLAKE_JWT"
    private_key              = file("/root/.ssh/rsa_key.p8")
    preview_features_enabled = [
      "snowflake_table_resource",
      "snowflake_database_datasource",
      "snowflake_cortex_search_service_resource",
    ]
  }
  provider "snowflake" {
    alias                    = "securityadmin"
    role                     = "SECURITYADMIN"
    authenticator            = "SNOWFLAKE_JWT"
    private_key              = file("/root/.ssh/rsa_key.p8")
    preview_features_enabled = [
      "snowflake_table_resource",
      "snowflake_database_datasource",
      "snowflake_cortex_search_service_resource",
    ]
  }
  provider "snowflake" {
    alias                    = "sysadmin"
    role                     = "SYSADMIN"
    authenticator            = "SNOWFLAKE_JWT"
    private_key              = file("/root/.ssh/rsa_key.p8")
    preview_features_enabled = [
      "snowflake_table_resource",
      "snowflake_database_datasource",
      "snowflake_cortex_search_service_resource",
    ]
  }

EOF
}
