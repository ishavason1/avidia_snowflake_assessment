#!/usr/bin/env python3
"""Upload one complete synthetic snapshot and run the canonical SQL RAW reload.

Uses the Snowflake connector's configured default connection. Existing RAW
tables are truncated, not replaced, so table policies and grants are retained.
"""

import csv
from pathlib import Path

import snowflake.connector


ROOT = Path(__file__).resolve().parents[1]
FILES_TO_LOAD = {
    "customers.csv": "CUSTOMER",
    "accounts.csv": "ACCOUNT",
    "transactions.csv": "TRANSACTION",
    "loans.csv": "LOAN",
    "gl_control.csv": "GL_CONTROL",
    "branches.csv": "BRANCH",
    "products.csv": "PRODUCT"
}


def main():
    # Check the entire input set before connecting or truncating any table.
    expected_counts = {}
    for filename, table in FILES_TO_LOAD.items():
        with (ROOT / "data" / filename).open(newline="") as csv_file:
            reader = csv.DictReader(csv_file)
            expected_counts[table] = sum(1 for _ in reader)
        if expected_counts[table] == 0:
            raise ValueError(f"Empty snapshot input: {filename}")

    with snowflake.connector.connect() as conn:
        with conn.cursor() as cursor:
            cursor.execute("USE ROLE DATA_OWNER")
            cursor.execute("USE WAREHOUSE TRANSFORM_WH")
            cursor.execute("CREATE STAGE IF NOT EXISTS RAW.PUBLIC.RAW_DATA_STAGE")
            for filename in FILES_TO_LOAD:
                file_uri = (ROOT / "data" / filename).as_uri().replace("'", "''")
                cursor.execute(
                    f"PUT '{file_uri}' @RAW.PUBLIC.RAW_DATA_STAGE "
                    "AUTO_COMPRESS=FALSE OVERWRITE=TRUE"
                )
                for result in cursor.fetchall():
                    if result[6] not in ("UPLOADED", "SKIPPED"):
                        raise RuntimeError(f"Upload failed for {filename}: {result[6]}")

        # One authoritative schema/load implementation; errors abort the rebuild.
        with (ROOT / "setup" / "load_raw.sql").open() as sql_file:
            for cursor in conn.execute_stream(sql_file):
                cursor.close()

        with conn.cursor() as cursor:
            for table, expected in expected_counts.items():
                cursor.execute(f"SELECT COUNT(*) FROM RAW.PUBLIC.{table}")
                actual = cursor.fetchone()[0]
                if actual != expected:
                    raise RuntimeError(f"{table}: loaded {actual} rows, expected {expected}")
                print(f"{table}: {actual} rows reloaded")


if __name__ == "__main__":
    main()
