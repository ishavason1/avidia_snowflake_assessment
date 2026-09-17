# Avidia Bank - Snowflake Data Governance Assessment

## Overview
Complete data catalog and metadata management system on Snowflake Horizon, proving 7 capabilities:
Owned, Defined, Traceable, Trusted, Secure, Adopted, Reconciled

## Quick Start
1. Run `setup/00_FULL_RUN.sql` in Snowflake
2. Run Python generator: `python data/generator.py`
3. Run dbt: `dbt build`
4. Review evidence in `evidence/`

## Structure
- `setup/` - Infrastructure setup
- `data/` - Data generation
- `dbt_project/` - Transformations (RAW → STAGING → MARTS)
- `metadata/` - Catalog foundation
- `classification/` - PII detection & approval
- `protection/` - Masking & row policies
- `dq/` - Data quality checks
- `lineage/` - Lineage tracking
- `catalog_app/` - Streamlit discovery
- `certification/` - CERTIFY procedure
- `scorecard/` - Seven words scoring
- `evidence/` - Proof outputs

## Hours Log
See HOURS.md

## Setup Instructions

### Running Infrastructure Setup
The infrastructure setup consists of 4 SQL files that must be run **in order**:

```bash
# Step 1: Create roles
snow sql -f setup/00_create_roles.sql

# Step 2: Create warehouses
snow sql -f setup/01_create_warehouses.sql

# Step 3: Create databases
snow sql -f setup/02_create_databases.sql

# Step 4: Grant permissions
snow sql -f setup/03_grant_permissions.sql
```

**Note:** Files are run individually because Snowflake CLI (`snow sql`) does not support the `@` include syntax (that's a Web UI feature). Each file is idempotent and can be re-run safely.

### Verification
```bash
snow sql -c default -q "SHOW ROLES;"
snow sql -c default -q "SHOW WAREHOUSES;"
snow sql -c default -q "SHOW DATABASES;"
```

## Block 0: Data Foundation ✅ COMPLETE

### What's Built
- 3,500 customers (seeded, reproducible)
- 7,039 deposit accounts
- 50,000 transactions
- 1,500 loans
- GL control totals for reconciliation
- Snowflake infrastructure (5 roles, 2 warehouses, 3 databases)

### Reproducibility
```bash
# Rebuild identical data anytime:
python data/generator.py  # Seed=42, always same output

# Rebuild infrastructure:
python setup/load_data.py  # Uses ~/.snowflake/config.toml
```

### Security
- ✅ No hardcoded credentials (uses config file)
- ✅ Credentials in .gitignore
- ✅ All code version-controlled
- ✅ Sealed sensitive columns baseline (before classification)

### Time Spent
Block 0: 1:50 hours
