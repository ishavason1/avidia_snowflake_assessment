#!/usr/bin/env python3
"""
data/generator.py

Generate realistic, reproducible banking data for Avidia assessment.

Seeded random keeps synthetic choices reproducible. Dates are relative to the
generation time; regenerate all files together for a new current snapshot.

Run: python data/generator.py
Output: data/customers.csv, data/accounts.csv, data/transactions.csv, etc.
"""

import pandas as pd
import random
from faker import Faker
from datetime import datetime, timedelta
import json
import sys

# ============================================
# CRITICAL: SEEDED RANDOM FOR REPRODUCIBILITY
# ============================================
SEED = 42  # Reproducible random business values; snapshot/audit dates may vary
random.seed(SEED)
Faker.seed(SEED)
fake = Faker(['en_US'])

snapshot_time = datetime.now()
print(f"[Generator] Seed={SEED}, snapshot={snapshot_time.date()}")

# ============================================
# CONFIG
# ============================================
NUM_CUSTOMERS = 3500  # ≥3,000 required
NUM_ACCOUNTS_PER_CUSTOMER = 2  # Average
NUM_TRANSACTIONS = 50000
NUM_LOANS = 1500
NUM_BRANCHES = 15

# ============================================
# 1. GENERATE CUSTOMERS (PERSONS + BUSINESSES)
# ============================================
print("\n[1/6] Generating customers...")
customers = []

for i in range(NUM_CUSTOMERS):
    cust_id = f"CUST_{i+1:06d}"
    cust_type = random.choice(['PERSON', 'BUSINESS'])
    
    if cust_type == 'PERSON':
        first_name = fake.first_name()
        last_name = fake.last_name()
        # TAX_ID will be detected as SENSITIVE (PII)
        tax_id = fake.ssn()  # Format: 123-45-6789
        dob = fake.date_of_birth(minimum_age=18, maximum_age=85).isoformat()
    else:  # BUSINESS
        first_name = fake.company()
        last_name = ""
        # EIN format: 12-3456789
        tax_id = f"{random.randint(10,99)}-{random.randint(1000000,9999999)}"
        dob = None
    
    customers.append({
        'CUSTOMER_ID': cust_id,
        'FIRST_NAME': first_name,
        'LAST_NAME': last_name,
        'CUSTOMER_TYPE': cust_type,
        'TAX_ID': tax_id,  # SENSITIVE: Will be masked
        'DATE_OF_BIRTH': dob,  # SENSITIVE: Will be masked
        'EMAIL': fake.email(),  # SENSITIVE: Will be masked
        'PHONE': fake.phone_number(),  # SENSITIVE: Will be masked
        'ADDRESS': fake.address().replace('\n', ', '),
        'CREATED_AT': (datetime.now() - timedelta(days=random.randint(1, 730))).isoformat(),
    })

customers_df = pd.DataFrame(customers)
customers_df.to_csv('data/customers.csv', index=False)
print(f"  ✓ {len(customers_df)} customers")

# ============================================
# 2. GENERATE ACCOUNTS (DEPOSIT ACCOUNTS)
# ============================================
print("[2/6] Generating accounts...")
accounts = []
account_id_counter = 1

for cust_idx in range(NUM_CUSTOMERS):
    cust_id = customers_df.iloc[cust_idx]['CUSTOMER_ID']
    
    # Random 1-3 accounts per customer
    num_accts = random.randint(1, 3)
    
    for _ in range(num_accts):
        acct_id = f"ACCT_{account_id_counter:08d}"
        account_id_counter += 1
        
        accounts.append({
            'ACCOUNT_ID': acct_id,
            'CUSTOMER_ID': cust_id,
            'ACCOUNT_TYPE': random.choice(['CHECKING', 'SAVINGS', 'MONEY_MARKET']),
            'ACCOUNT_NUMBER': f"{random.randint(100000000, 999999999)}",  # SENSITIVE
            'BRANCH_CODE': f"BR_{random.randint(1, NUM_BRANCHES):02d}",  # For row access policy test
            'BALANCE': round(random.uniform(100, 500000), 2),
            'STATUS': random.choice(['ACTIVE', 'INACTIVE', 'CLOSED']),
            'OPENED_DATE': (snapshot_time - timedelta(days=random.randint(30, 1825))).date().isoformat(),
            'CREATED_AT': datetime.now().isoformat(),
        })

accounts_df = pd.DataFrame(accounts)
accounts_df.to_csv('data/accounts.csv', index=False)
print(f"  ✓ {len(accounts_df)} accounts")

# ============================================
# 3. GENERATE TRANSACTIONS (50,000+)
# ============================================
print("[3/6] Generating transactions...")
transactions = []

for i in range(NUM_TRANSACTIONS):
    acct_id = random.choice(accounts_df['ACCOUNT_ID'].tolist())
    
    transactions.append({
        'TRANSACTION_ID': f"TXN_{i+1:08d}",
        'ACCOUNT_ID': acct_id,
        'TRANSACTION_TYPE': random.choice(['DEBIT', 'CREDIT']),
        'AMOUNT': round(random.uniform(10, 10000), 2),
        'BUSINESS_DATE': (snapshot_time - timedelta(days=random.randint(0, 90))).date().isoformat(),
        'MEMO': fake.sentence(),
        'CREATED_AT': datetime.now().isoformat(),
    })

transactions_df = pd.DataFrame(transactions)
transactions_df.to_csv('data/transactions.csv', index=False)
print(f"  ✓ {len(transactions_df)} transactions")

# ============================================
# 4. GENERATE LOANS (1,500+)
# ============================================
print("[4/6] Generating loans...")
loans = []

for i in range(NUM_LOANS):
    cust_id = random.choice(customers_df['CUSTOMER_ID'].tolist())
    acct_id = random.choice(accounts_df['ACCOUNT_ID'].tolist())
    
    loans.append({
        'LOAN_ID': f"LOAN_{i+1:06d}",
        'CUSTOMER_ID': cust_id,
        'ACCOUNT_ID': acct_id,
        'LOAN_TYPE': random.choice(['PERSONAL', 'HOME', 'AUTO', 'BUSINESS']),
        'PRINCIPAL': round(random.uniform(5000, 500000), 2),
        'INTEREST_RATE': round(random.uniform(3.5, 9.5), 2),
        'CREDIT_GRADE': random.choice(['A', 'B', 'C', 'D']),
        'COLLATERAL_VALUE': round(random.uniform(5000, 750000), 2),
        'LOAN_MEMO': ( "Auto-pay card on file: 4532-0151-1283-0366 for synthetic testing only."
                     if (i + 1) % 20 == 0 else fake.sentence()),  # DELIBERATELY SENSITIVE: May contain hidden card numbers
        'STATUS': random.choice(['ACTIVE', 'PAID_OFF', 'DEFAULTED']),
        'ORIGINATION_DATE': (snapshot_time - timedelta(days=random.randint(30, 1825))).date().isoformat(),
    })

loans_df = pd.DataFrame(loans)
loans_df.to_csv('data/loans.csv', index=False)
print(f"  ✓ {len(loans_df)} loans")

# ============================================
# 5. GENERATE GL CONTROL TOTALS (Reconciliation)
# ============================================
print("[5/6] Generating GL control totals...")

# Same population as MART_DEPOSITS; controls remain separate from account rows.
eligible_deposits = accounts_df[
    (accounts_df['STATUS'] == 'ACTIVE')
    & accounts_df['ACCOUNT_TYPE'].isin(['CHECKING', 'SAVINGS'])
]
total_deposits_by_type = eligible_deposits.groupby('ACCOUNT_TYPE').agg(
    CONTROL_TOTAL=('BALANCE', 'sum'),
    RECORD_COUNT=('ACCOUNT_ID', 'size'),
).reset_index()

# Create GL control table
gl_controls = []
for _, row in total_deposits_by_type.iterrows():
    gl_controls.append({
        'GL_CODE': f"GL_{random.randint(10000, 99999)}",
        'ACCOUNT_TYPE': row['ACCOUNT_TYPE'],
        'CONTROL_TOTAL': round(row['CONTROL_TOTAL'], 2),
        'RECORD_COUNT': row['RECORD_COUNT'],
        'AS_OF_DATE': snapshot_time.date().isoformat(),
    })

gl_controls_df = pd.DataFrame(gl_controls)
gl_controls_df.to_csv('data/gl_control.csv', index=False)
print(f"  ✓ {len(gl_controls_df)} GL control records")

# ============================================
# 6. REFERENCE DATA (BRANCHES, PRODUCTS, OFFICERS)
# ============================================
print("[6/6] Generating reference data...")

# Branches
branches = []
for i in range(NUM_BRANCHES):
    branches.append({
        'BRANCH_CODE': f"BR_{i+1:02d}",
        'BRANCH_NAME': f"{fake.city()} Branch",
        'BRANCH_MANAGER': fake.name(),
        'REGION': random.choice(['NORTH', 'SOUTH', 'EAST', 'WEST']),
    })
branches_df = pd.DataFrame(branches)
branches_df.to_csv('data/branches.csv', index=False)
print(f"  ✓ {len(branches_df)} branches")

# Products
products = []
for acct_type in ['CHECKING', 'SAVINGS', 'MONEY_MARKET']:
    for tier in ['BASIC', 'PREMIUM', 'VIP']:
        products.append({
            'PRODUCT_CODE': f"PROD_{acct_type[:4]}_{tier[:3]}",
            'PRODUCT_NAME': f"{acct_type} - {tier}",
            'ACCOUNT_TYPE': acct_type,
            'TIER': tier,
        })
products_df = pd.DataFrame(products)
products_df.to_csv('data/products.csv', index=False)
print(f"  ✓ {len(products_df)} products")

# ============================================
# SUMMARY
# ============================================
print("\n" + "="*60)
print("DATA GENERATION COMPLETE")
print("="*60)
print(f"Customers:     {len(customers_df)}")
print(f"Accounts:      {len(accounts_df)}")
print(f"Transactions:  {len(transactions_df)}")
print(f"Loans:         {len(loans_df)}")
print(f"GL Controls:   {len(gl_controls_df)}")
print(f"Branches:      {len(branches_df)}")
print(f"Products:      {len(products_df)}")
print("="*60)
print(f"\nAll files saved to: data/")
print(f"Seed used: {SEED}; snapshot date: {snapshot_time.date()}")
