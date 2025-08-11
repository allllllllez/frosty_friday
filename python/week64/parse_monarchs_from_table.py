#!/usr/bin/env python3

"""
Week-64 Python でXMLをパースしてもいいじゃない
"""

from lxml import etree
from snowflake.snowpark import Session

import os
from pathlib import Path
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


def parse_monarchs_xml(xml_string):
    """
    君主のXMLデータを解析し、各君主の情報を辞書のリストとして返す
    
    Args:
        xml_string: 解析対象のXML文字列
        
    Returns:
        list: 各君主の情報を含む辞書のリスト
    """
    root = etree.fromstring(xml_string)
    
    monarchs_data = []
    
    for dynasty in root:
        dynasty_name = dynasty.get('name', '')
        
        monarch_elements = dynasty.xpath('.//Monarch')
        
        for monarch in monarch_elements:
            monarch_info = {
                'DYNASTY': dynasty_name,
                'NAME': monarch.findtext('Name', ''),
                'REIGN': monarch.findtext('Reign', ''),
                'SUCCESSION': monarch.findtext('Succession', ''),
                'LIFE_DETAILS': monarch.findtext('LifeDetails', '')
            }
            monarchs_data.append(monarch_info)
    
    return monarchs_data


def frostyfriday_week64(session:Session, table_name: str):
    """
    指定されたテーブルからXMLデータを読み込み、君主情報を抽出してDataFrameとして返す
    
    Args:
        session: SnowflakeのSessionオブジェクト
        table_name: XMLデータが格納されているテーブル名
        
    Returns:
        DataFrame: 君主情報を含むSnowpark DataFrame
    """
    dataframe = session.table(table_name)
    data = dataframe.to_pandas()["DATA"][0]
    
    monarchs_data = parse_monarchs_xml(data)
    return session.create_dataframe(monarchs_data)


def main():
    """Week-64チャレンジの実行例"""
    
    session = create_session()
    
    try:
        dataframe = frostyfriday_week64(session, "WEEK64")
        dataframe.show()
        
    finally:
        session.close()


if __name__ == "__main__":
    main()
