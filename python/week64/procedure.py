from snowflake.core import Root, CreateMode
from snowflake.core.procedure import Argument, ColumnType, Procedure, ReturnTable, PythonFunction, CallArgument, CallArgumentList
from pathlib import Path
import os
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session


def get_private_key():
    """RSA秘密鍵ファイルを読み込み、暗号化オブジェクトとして返す"""
    private_key_path = os.environ.get('SNOWFLAKE_PRIVATE_KEY_PATH', '~/.ssh/rsa_key.p8')
    private_key_path = Path(private_key_path).expanduser()
    
    with open(private_key_path, 'rb') as key_file:
        key_data = key_file.read()
        
    passphrase = os.environ.get('SNOWFLAKE_PRIVATE_KEY_PASSPHRASE', '')
    
    try:
        if passphrase:
            private_key = serialization.load_pem_private_key(
                key_data,
                password=passphrase.encode(),
                backend=default_backend()
            )
        else:
            private_key = serialization.load_pem_private_key(
                key_data,
                password=None,
                backend=default_backend()
            )
    except TypeError:
        private_key = serialization.load_pem_private_key(
            key_data,
            password=None,
            backend=default_backend()
        )
    
    return private_key


def create_session() -> Session:
    """Snowflake のときは Snowflake セッション取得、ローカルのときは環境変数を使用してSnowflakeセッションを作成する"""
    current_session = None

    try:
        current_session = get_active_session()
    except Exception:
        connection_params = {
            'account': os.environ['SNOWFLAKE_ACCOUNT'],
            'user': os.environ['SNOWFLAKE_USER'],
            'role': os.environ.get('SNOWFLAKE_ROLE'),
            'warehouse': os.environ.get('SNOWFLAKE_WAREHOUSE'),
            'database': os.environ.get('SNOWFLAKE_DATABASE'),
            'schema': os.environ.get('SNOWFLAKE_SCHEMA'),
        }
        
        if os.environ.get('SNOWFLAKE_PRIVATE_KEY_PATH'):
            connection_params['private_key'] = get_private_key()
        else:
            connection_params['password'] = os.environ.get('SNOWFLAKE_PASSWORD')
    
        current_session = Session.builder.configs(connection_params).create()

    return current_session


def create_week64_prodedure(root, database, schema):
    """
    Snowflakeのストアドプロシージャを作成する関数
    """
    content = Path('./parse_monarchs_from_table.py').read_text()
    
    # ストアドプロシージャの定義
    procedure = Procedure(
        name="parse_monarchs_from_table",
        arguments=[
            Argument(name="table_name", datatype="VARCHAR")
        ],
        return_type=ReturnTable(
            column_list=[
                ColumnType(name="DYNASTY", datatype="VARCHAR"),
                ColumnType(name="NAME", datatype="VARCHAR"),
                ColumnType(name="REIGN", datatype="VARCHAR"),
                ColumnType(name="SUCCESSION", datatype="VARCHAR"),
                ColumnType(name="LIFE_DETAILS", datatype="VARCHAR"),
            ]
        ),
        language_config=PythonFunction(
          runtime_version="3.11",
          packages=[
            "snowflake-snowpark-python",
            "lxml",
            "cryptography"
          ],
          handler="frostyfriday_week64"
        ),
        mode=CreateMode.or_replace,
        body=f"{content}",
    )

    procedures = root.databases[database].schemas[schema].procedures
    procedures.create(procedure)


def call_week64_prodedure(root, database, schema, table, procedure):
    procedure_reference = root.databases[database].schemas[schema].procedures[procedure]
    call_argument_list = CallArgumentList(
        call_arguments=[
            CallArgument(name="table_name", datatype="VARCHAR", value=table)
        ]
    )
    data = procedure_reference.call(call_argument_list)
    data.show()


def main():
    """
    ストアドプロシージャを作成、実行するメイン関数
    """
    session = create_session()
    root = Root(session)

    create_week64_prodedure(root, "M_KAJIYA_FROSTY_FRIDAY", "WEEK64")
    # call_week64_prodedure(root, "M_KAJIYA_FROSTY_FRIDAY", "WEEK64", "WEEK64", "PARSE_MONARCHS_FROM_TABLE(VARCHAR)") 
    # snowflake.core.exceptions.ServerError: (500) となるので ↑ はコメントアウト
    # Reason: Internal Server Error
    # Error Message: Unexpected end-of-input: expected close marker for Array (start marker at [Source: (com.snowflake.snowapi.rest.SnowapiUtils$JsonInputStreamForByteArray); line: 1, column: 1])
    #  at [Source: (com.snowflake.snowapi.rest.SnowapiUtils$JsonInputStreamForByteArray); line: 1, column: 2]
    # HTTP response code: 500


if __name__ == "__main__":
    main()
