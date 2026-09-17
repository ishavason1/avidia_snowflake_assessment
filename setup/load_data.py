#!/usr/bin/env python3
"""
Load CSV files to Snowflake using pandas
Direct insert - no staging needed!
"""

import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
import pandas as pd
from pathlib import Path

# Connect using config file (no hardcoded creds)
try:
    conn = snowflake.connector.connect()
except Exception as e:
    print(f"✗ Connection failed: {e}")
    print("Make sure ~/.snowflake/config.toml exists with valid credentials")
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
        # Read CSV
        df = pd.read_csv(csv_path)
        
        # Write to Snowflake (auto-creates table)
        success, nchunks, nrows, _ = write_pandas(
            conn,
            df,
            table_name,
            auto_create_table=True,
            overwrite=False
        )
        
        print(f"✓ {table_name}: {len(df)} rows loaded")
        
    except Exception as e:
        print(f"✗ Error loading {table_name}: {e}")

print("\n" + "=" * 60)
print("✓ DATA LOAD COMPLETE")
print("=" * 60)

# Verify row counts
print("\nVerification:")
for table_name in files_to_load.values():
    try:
        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cursor.fetchone()[0]
        print(f"  {table_name}: {count} rows")
    except:
        pass

conn.close()
