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
