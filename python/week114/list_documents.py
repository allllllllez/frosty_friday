#!/usr/bin/env python3
"""
week-114: documents_with_url を一覧表示する

sql/week-114.sql の解法1を実行した後、file_name / title / presigned_url を
チャレンジのスクリーンショットと同じ見た目（区切り線付き）で表示する。
"""

import os
import sys
from pathlib import Path

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from snowflake.connector import connect

TABLE = "M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_with_url"
TITLE_MODEL = "llama3.1-8b"
TITLE_PROMPT = "次の論文のタイトルを答えて。タイトル以外は出力不要\n\n"


def get_private_key():
    private_key_path = os.environ.get("SNOWFLAKE_PRIVATE_KEY_PATH", "~/.ssh/rsa_key.p8")
    private_key_path = Path(private_key_path).expanduser()

    with open(private_key_path, "rb") as key_file:
        key_data = key_file.read()

    passphrase = os.environ.get("SNOWFLAKE_PRIVATE_KEY_PASSPHRASE", "")

    try:
        if passphrase:
            return serialization.load_pem_private_key(
                key_data, password=passphrase.encode(), backend=default_backend()
            )
        return serialization.load_pem_private_key(
            key_data, password=None, backend=default_backend()
        )
    except TypeError:
        return serialization.load_pem_private_key(
            key_data, password=None, backend=default_backend()
        )


def create_connection():
    connection_params = {
        "account": os.environ["SNOWFLAKE_ACCOUNT"],
        "user": os.environ["SNOWFLAKE_USER"],
        "role": os.environ.get("SNOWFLAKE_ROLE"),
        "warehouse": os.environ.get("SNOWFLAKE_WAREHOUSE"),
    }

    if os.environ.get("SNOWFLAKE_PRIVATE_KEY_PATH"):
        connection_params["private_key"] = get_private_key()
    else:
        connection_params["password"] = os.environ.get("SNOWFLAKE_PASSWORD")

    return connect(**connection_params)


def fetch_documents(conn):
    query = f"""
        select
            file_name,
            snowflake.cortex.ai_complete(
                '{TITLE_MODEL}',
                '{TITLE_PROMPT}' || content
            ) as title,
            presigned_url
        from {TABLE}
        order by file_name
    """
    cursor = conn.cursor()
    try:
        cursor.execute(query)
        return cursor.fetchall()
    finally:
        cursor.close()


def print_documents(rows):
    print("--------")
    for file_name, title, presigned_url in rows:
        print(f"{file_name} -- {title}")
        print(presigned_url)
        print("--------")


def main():
    conn = create_connection()
    try:
        rows = fetch_documents(conn)
    finally:
        conn.close()

    if not rows:
        print("documents_with_url に行がありません。sql/week-114.sql の解法1を先に実行してください。", file=sys.stderr)
        return

    print_documents(rows)


if __name__ == "__main__":
    main()
