terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.99.0"
    }
  }

  required_version = "~> 1.9"
}

provider "snowflake" {
  alias         = "accountadmin"
  role          = "ACCOUNTADMIN"
  account       = local.account
  authenticator = "JWT" # 指定しないとパスワード認証になってしまう問題への一時的な対処 https://github.com/Snowflake-Labs/terraform-provider-snowflake/issues/2169#issuecomment-1816046269
}

provider "snowflake" {
  alias         = "useradmin"
  role          = "USERADMIN"
  account       = local.account
  authenticator = "JWT" # 指定しないとパスワード認証になってしまう問題への一時的な対処 https://github.com/Snowflake-Labs/terraform-provider-snowflake/issues/2169#issuecomment-1816046269
}

