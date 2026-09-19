data "snowflake_database" "this" {
  provider = snowflake.sysadmin

  name = var.database_name
}
