#!/usr/bin/env python3
"""
Load CSV files to Snowflake using credentials from ~/.snowflake/config.toml
NO hardcoded credentials!
"""

import snowflake.connector
from pathlib import Path
import os

# Get credentials from environment or config file
# snowflake-connector reads ~/.snowflake/config.toml automatically
try:
    conn = snowflake.connector.connect()  # Uses default connection from config
except Exception as e:
    print(f"✗ Failed to connect. Make sure ~/.snowflake/config.toml exists")
    print(f"Error: {e}")
    exit(1)

cursor = conn.cursor()

# Set database/schema
cursor.execute("USE DATABASE RAW")
cursor.execute("USE SCHEMA PUBLIC")

files_to_load = {
    "customers.csv": "CUSTOMER",
    "accounts.csv": "ACCOUNT",
    "transactions.csv": "TRANSACTION",
    "loans.csv": "LOAN",
    "gl_control.csv": "GL_CONTROL",
    "branches.csv": "BRANCH",
    "products.csv": "PRODUCT"
}

print("=" * 60)
print("LOADING DATA TO SNOWFLAKE")
print("=" * 60)

for csv_file, table_name in files_to_load.items():
    csv_path = Path(f"data/{csv_file}")
    
    if not csv_path.exists():
        print(f"⚠ {csv_file} not found, skipping")
        continue
    
    print(f"\n📥 Loading {csv_file} → {table_name}")
    
    try:
        # Use file:// URL
        sql = f"""
        COPY INTO {table_name}
        FROM 'file://{csv_path.absolute()}'
        FILE_FORMAT = (
            TYPE = 'CSV',
            SKIP_HEADER = 1,
            FIELD_DELIMITER = ',',
            NULL_IF = ('NULL', 'null', '')
        )
        ON_ERROR = 'CONTINUE'
        """
        
        cursor.execute(sql)
        
        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cursor.fetchone()[0]
        print(f"✓ {table_name}: {count} rows loaded")
        
    except Exception as e:
        print(f"✗ Error: {e}")

print("\n" + "=" * 60)
print("✓ DATA LOAD COMPLETE")
print("=" * 60)

conn.close()
