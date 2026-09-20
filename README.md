# Avidia Bank - Snowflake Data Governance Assessment

## Overview
Complete data catalog and metadata management system on Snowflake Horizon, proving 7 capabilities:
Owned, Defined, Traceable, Trusted, Secure, Adopted, Reconciled

## Quick Start
1. Run the four infrastructure scripts below if needed.
2. Follow the foundation rebuild commands below to regenerate one complete snapshot and reload RAW.
3. Use the repository-root dbt project and the scoped foundation commands below.

## Structure
- `setup/` - Infrastructure setup
- `data/` - Data generation
- `dbt/models/` - Transformations (RAW → STAGING → MARTS)
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

## Deposits foundation

### What's Built
- 3,500 customers (seeded, reproducible)
- 7,039 deposit accounts
- 50,000 transactions
- 1,500 loans
- GL control totals for reconciliation
- Snowflake infrastructure (5 roles, 2 warehouses, 3 databases)

### Rebuild and validation

Run from the repository root with the project's Python environment activated.
Random synthetic business values are reproducible from seed 42, while snapshot
and audit dates may vary by execution; generated files are not byte-identical
across runs. Regenerate all CSVs together; the previously checked-in CSVs use the
old transaction/GL contract.

`setup/load_data.py` is the supported rebuild entry point. It uploads the seven
CSVs and invokes `setup/load_raw.sql`, the single authoritative RAW schema/load
implementation. Each table is truncated before COPY, so rerunning does not append
duplicates. Existing tables, grants and policies are retained. CSV quoting is
handled explicitly and load errors abort instead of silently skipping records.
The reload is not atomic across tables: after any failure, rerun it successfully
before dbt. The configured default Snowflake connector connection must be able
to use DATA_OWNER and TRANSFORM_WH; no credentials are stored in this repository.
DATA_OWNER needs CREATE STAGE on RAW.PUBLIC (included in the grants script).

```bash
source venv/bin/activate

# Apply the additional RAW stage privilege once, as ACCOUNTADMIN:
snow sql -q 'USE ROLE ACCOUNTADMIN; GRANT CREATE STAGE ON SCHEMA RAW.PUBLIC TO ROLE DATA_OWNER;'

# Regenerate one complete current snapshot and reload it (replaces table contents):
python data/generator.py &&
python setup/load_data.py

# Test RAW contracts first; only continue on success:
dbt test --select source:raw.account source:raw.customer source:raw.transaction source:raw.gl_control --exclude 'path:dbt/tests/test_mart_deposits_*.sql'

# Build upstream staging, the mart, and its structural/model tests:
dbt build --select +mart_deposits --exclude 'path:dbt/tests/test_mart_deposits_*.sql'

# Resolve the actual relation names for the validation SQL:
dbt ls --select mart_deposits stg_transaction --resource-type model --output json --output-keys name relation_name
```

The repository-root `dbt_project.yml` is the only project. Its source/model tests,
foundation empty-mart test, and six existing DQ tests remain discoverable. The
commands above exclude the six deferred DQ test SQL files from foundation runs.
Automatic DQ_RESULT persistence is disabled pending review; the macro remains
unchanged. Existing test-failure storage configuration is retained, so executing
tests can still store failure tables. The six DQ checks require separate review
before an unrestricted build is used as assessment evidence.

The mart is a current account snapshot keyed only by ACCOUNT_ID, containing ACTIVE
CHECKING/SAVINGS accounts. RAW and staged account/customer keys are tested for
uniqueness; duplicates are not hidden with DISTINCT. Its structural nonempty test
is separate from the six DQ dimensions. `LATEST_BUSINESS_DATE` is retained for
compatibility and now means MAX(valid staged transaction BUSINESS_DATE), nullable
when no dated transaction exists. OPENED_DATE remains independent.

GL controls are separate, one row per eligible ACCOUNT_TYPE and source AS_OF_DATE,
with balances and counts derived from those same active accounts. No GL fields or
joins remain in the mart. Reconcile this source snapshot by type in the later DQ
step; DBT_BUSINESS_DATE is the build date, not proof of source snapshot date.

Run `setup/validate_deposits_foundation.sql` after setting its two relation names
to the `dbt ls` output. dbt may prefix custom schemas with the target schema.
The script checks nonempty populations, keys, transaction domains, GL controls,
and exact eligible-account membership/multiplicity without hardcoded totals.

### Security
- ✅ No hardcoded credentials (uses config file)
- ✅ Credentials in .gitignore
- ✅ All code version-controlled
- ✅ Sealed sensitive columns baseline (before classification)

### Time Spent
Block 0: 1:50 hours
