resource "random_password" "initial_password" {
  length = 16
}

# 人間にあたるユーザーは snowflake_user で作るのが正しいけど、今回はアカウントに MFA 必須ポリシーを設定しており、MFA 設定が面倒なのでスキップ
resource "snowflake_legacy_service_user" "user" {
  for_each = {
    for u in local.users : u.user_name => u
  }

  provider     = snowflake.useradmin
  name         = each.value.user_name
  default_role = each.value.role
  password     = random_password.initial_password.result
}

# v0.99.0 現在、セッションポリシーはまだないのです。。。なので無理やり作ります
# SQL で書けさえすれば、お好きなオブジェクトをリソースにすることができる snowflake_unsafe_execute を利用します
# https://registry.terraform.io/providers/snowflake-labs/snowflake/latest/docs/resources/unsafe_execute
resource "snowflake_unsafe_execute" "session_policy" {
  for_each = {
    for p in local.session_policies : p.name => p
  }

  provider = snowflake.accountadmin

  execute = join(
    " ",
    [
      "create or replace session policy ${each.value.name}",
      "%{if lookup(each.value, "session_idle_timeout_mins", null) != ""}session_idle_timeout_mins = ${each.value.session_idle_timeout_mins}%{endif}",
      "%{if lookup(each.value, "session_ui_idle_timeout_mins", null) != ""}session_ui_idle_timeout_mins = ${each.value.session_ui_idle_timeout_mins}%{endif}"
    ]
  )

  query  = "show session policies like '${each.value.name}'"
  revert = "drop session policy ${each.value.name}"
}

# v0.99.0 現在、セッションポリシーのアタッチもまだないので。。。
resource "snowflake_unsafe_execute" "user_session_policy_attachment" {
  for_each = {
    for u in local.users : u.user_name => u
  }

  provider = snowflake.accountadmin

  execute = "alter user ${snowflake_legacy_service_user.user[each.value.user_name].name} set session policy ${each.value.session_policy}"
  revert  = "alter user ${snowflake_legacy_service_user.user[each.value.user_name].name} unset session policy"

  # snowflake_unsafe_execute.session_policy[<policy_name>] で指定できないので参照関係がない
  depends_on = [
    snowflake_unsafe_execute.session_policy
  ]
}
