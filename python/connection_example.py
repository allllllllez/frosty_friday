#!/usr/bin/env python3
"""
Snowflake Python API connection example
"""

import os
from pathlib import Path
from snowflake.core import Root
from snowflake.connector import connect
from snowflake.connector.connection import SnowflakeConnection
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization


def get_private_key():
    """Load private key from file"""
    private_key_path = os.environ.get('SNOWFLAKE_PRIVATE_KEY_PATH', '~/.ssh/rsa_key.p8')
    private_key_path = Path(private_key_path).expanduser()
    
    with open(private_key_path, 'rb') as key_file:
        key_data = key_file.read()
        
    # Try loading with passphrase first
    passphrase = os.environ.get('SNOWFLAKE_PRIVATE_KEY_PASSPHRASE', '')
    
    try:
        if passphrase:
            private_key = serialization.load_pem_private_key(
                key_data,
                password=passphrase.encode(),
                backend=default_backend()
            )
        else:
            # Try loading without password
            private_key = serialization.load_pem_private_key(
                key_data,
                password=None,
                backend=default_backend()
            )
    except TypeError:
        # If password was provided but key is not encrypted, try without password
        private_key = serialization.load_pem_private_key(
            key_data,
            password=None,
            backend=default_backend()
        )
    
    return private_key


def create_connection() -> SnowflakeConnection:
    """Create Snowflake connection using environment variables"""
    
    # Connection parameters
    connection_params = {
        'account': os.environ['SNOWFLAKE_ACCOUNT'],
        'user': os.environ['SNOWFLAKE_USER'],
        'role': os.environ.get('SNOWFLAKE_ROLE'),
        'warehouse': os.environ.get('SNOWFLAKE_WAREHOUSE'),
        'database': os.environ.get('SNOWFLAKE_DATABASE'),
        'schema': os.environ.get('SNOWFLAKE_SCHEMA'),
    }
    
    # Use private key if available
    if os.environ.get('SNOWFLAKE_PRIVATE_KEY_PATH'):
        connection_params['private_key'] = get_private_key()
    else:
        # Fall back to password authentication
        connection_params['password'] = os.environ.get('SNOWFLAKE_PASSWORD')
    
    return connect(**connection_params)


def main():
    """Example usage of Snowflake Python API"""
    
    # Create connection
    conn = create_connection()
    
    try:
        # Create Root object for API access
        root = Root(conn)
        
        # Example: List databases
        print("Available databases:")
        databases = root.databases.iter()
        for db in databases:
            print(f"  - {db.name}")
        
        # Example: Execute a query
        cursor = conn.cursor()
        cursor.execute("SELECT CURRENT_VERSION()")
        version = cursor.fetchone()
        print(f"\nSnowflake version: {version[0]}")
        
    finally:
        conn.close()


if __name__ == "__main__":
    main()