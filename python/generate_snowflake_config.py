#!/usr/bin/env python3
"""
Generate Snowflake CLI config from environment variables.
Reads from .env file and creates/updates .snowflake/config.toml
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import toml


def generate_snowflake_config():
    # Load environment variables from .env file
    env_path = Path(__file__).parent / '.env'
    if not env_path.exists():
        print(f"Error: {env_path} not found. Please copy .env.example to .env and configure it.")
        sys.exit(1)
    
    load_dotenv(env_path)
    
    # Read required environment variables
    required_vars = {
        'SNOWFLAKE_ACCOUNT': os.getenv('SNOWFLAKE_ACCOUNT'),
        'SNOWFLAKE_USER': os.getenv('SNOWFLAKE_USER'),
        'SNOWFLAKE_ROLE': os.getenv('SNOWFLAKE_ROLE'),
        'SNOWFLAKE_WAREHOUSE': os.getenv('SNOWFLAKE_WAREHOUSE'),
        'SNOWFLAKE_DATABASE': os.getenv('SNOWFLAKE_DATABASE'),
        'SNOWFLAKE_SCHEMA': os.getenv('SNOWFLAKE_SCHEMA'),
    }
    
    # Check if all required variables are set
    missing_vars = [k for k, v in required_vars.items() if not v]
    if missing_vars:
        print(f"Error: Missing required environment variables: {', '.join(missing_vars)}")
        sys.exit(1)
    
    # Path to config.toml
    config_path = Path.home() / '.snowflake' / 'config.toml'
    
    # Load existing config or create new one
    if config_path.exists():
        config = toml.load(config_path)
    else:
        config = {
            'default_connection_name': 'sandbox',
            'cli': {
                'ignore_new_version_warning': False,
                'logs': {
                    'save_logs': True,
                    'path': '/root/.snowflake/logs',
                    'level': 'info'
                }
            },
            'connections': {}
        }
    
    # Update sandbox connection
    config['connections']['sandbox'] = {
        'account': required_vars['SNOWFLAKE_ACCOUNT'],
        'user': required_vars['SNOWFLAKE_USER'],
        'database': required_vars['SNOWFLAKE_DATABASE'],
        'schema': required_vars['SNOWFLAKE_SCHEMA'],
        'warehouse': required_vars['SNOWFLAKE_WAREHOUSE'],
        'role': required_vars['SNOWFLAKE_ROLE'],
        'authenticator': 'SNOWFLAKE_JWT'
    }
    
    # Write updated config
    config_path.parent.mkdir(parents=True, exist_ok=True)
    with open(config_path, 'w') as f:
        toml.dump(config, f)
    
    print(f"Successfully generated {config_path}")
    print("\nConnection details:")
    for key, value in config['connections']['sandbox'].items():
        print(f"  {key}: {value}")


if __name__ == '__main__':
    generate_snowflake_config()