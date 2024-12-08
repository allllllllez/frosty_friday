locals {
  account = "<your_account>"

  users            = csvdecode(file("./user_csv/user.csv"))
  session_policies = csvdecode(file("./policy_csv/session_policy.csv"))
}
