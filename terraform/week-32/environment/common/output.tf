output "user_password" {
  value     = { for u in snowflake_legacy_service_user.user : u.name => u.password }
  sensitive = true # Error: Output refers to sensitive values
}
