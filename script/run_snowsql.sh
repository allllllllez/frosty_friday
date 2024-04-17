#!/usr/bin/env bash

# Usage:
#     run_snowsql.sh <query_file>
# Requirements:
#     - snowsql
#     - SnowSQL Environments:
#         SNOWSQL_ACCOUNT : アカウント名 https://docs.snowflake.com/ja/user-guide/admin-account-identifier#format-1-preferred-account-name-in-your-organization
#         SNOWSQL_USER : ユーザー名

root_dir="$(dirname $0)/.."
ssh_dir="${root_dir}/.ssh"
snowflake_keypair_path="${ssh_dir}/rsa_key.p8"

if [[ -z "$1" ]]; then
    echo "Please specify query file"
    exit 1
fi
query_file=$1


name=$(echo $(basename $query_file) | sed 's/\.[^\.]*$//')
log="${root_dir}/log/${name}.log"
log="${name}.log"

echo "" > $log 2>&1
snowsql \
    --private-key-path "${snowflake_keypair_path}" \
    -f "$query_file" \
    -o log_level=DEBUG \
    > $log 2>&1 
tail $log
