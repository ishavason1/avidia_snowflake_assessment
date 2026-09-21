# Avidia Bank — Data Catalog & Metadata Management on Snowflake

## Overview
This repository contains a reproducible Snowflake Enterprise trial implementation of a governed data catalog and metadata-management layer over synthetic banking data.

The solution proves, through runnable SQL/dbt code and query evidence, that a certified data product can be:
**OWNED · DEFINED · TRACEABLE · TRUSTED · SECURE · ADOPTED · RECONCILED**

Primary certified data product:
`ANALYTICS.MARTS.MART_DEPOSITS`

The implementation uses Snowflake SQL, dbt Core, Snowflake Horizon capabilities, Streamlit in Snowflake, GitHub, GitHub Actions, and Snowflake CLI.

## Architecture
```text
Synthetic Banking Data
        |
        v
RAW
  CUSTOMER / ACCOUNT / TRANSACTION / LOAN / GL_CONTROL / BRANCH / PRODUCT
        |
        v
ANALYTICS.STAGING
  dbt staging models
        |
        v
ANALYTICS.MARTS
  MART_DEPOSITS
  MART_CUSTOMER_360
        |
        +-----------------------------+
        |                             |
        v                             v
GOVERNANCE.CATALOG              GOVERNANCE.DQ
metadata / glossary / CDEs      DQ_RESULT
classification / certification
lineage / scorecard
        |
        v
Streamlit Data Catalog
```

## Repository Structure
```text
.github/workflows/   GitHub Actions CI pipeline
ci/                  CI zero-copy clone scripts and dbt CI profile
setup/               account, role, warehouse and CI bootstrap scripts
data/                synthetic-data assets, dictionary and sealed sensitive list
dbt/                 STAGING and MARTS dbt models and tests
metadata/            metadata harvest, tags, dictionary, glossary and CDE logic
classification/      classification profile, custom classifier, review and metrics
protection/          masking and row-access controls
quality/             six data-quality dimensions and DQ result persistence
lineage/             native, external and snapshot lineage
certification/       certification evidence, scorecard and CERTIFY procedure
streamlit/           Streamlit catalog application
HOURS.md             actual time spent
AI_DISCLOSURE.md     AI-assistance disclosure
```

## Environment
Snowflake Enterprise trial account.

Core databases / schemas:
```text
RAW.PUBLIC
ANALYTICS.STAGING
ANALYTICS.MARTS
GOVERNANCE.CATALOG
```

Primary warehouse:
`TRANSFORM_WH`

Main roles:
```text
DATA_OWNER
DATA_STEWARD
DEPOSITS_ANALYST
BRANCH_HUDSON
SVC_PIPELINE
```

`SVC_PIPELINE` is the non-ACCOUNTADMIN service role used by GitHub Actions through RSA key-pair authentication.

## Rebuild Order

### 1. One-time account bootstrap
Run the base setup scripts using an administrative role in a fresh Snowflake trial.

The CI-specific bootstrap files are:
```text
setup/04_ci_bootstrap.sql
setup/05_create_ci_service_user.sql
```

These are one-time administrative bootstrap scripts only. GitHub Actions never runs as `ACCOUNTADMIN`.

### 2. Generate and load synthetic data
Run the committed synthetic-data generation/load process under `data/` and load the RAW banking objects.

The dataset contains more than 3,000 customers and includes persons and businesses, deposit accounts, transactions, loans, GL control totals, branches, products and reference data.

The sealed sensitive-column baseline is committed before classification:
`data/sealed_sensitive_columns.json`

### 3. Build STAGING and MARTS
Run:
```bash
dbt build
```

For CI:
```bash
dbt build --profiles-dir ci
```

The final CI build completes successfully with 44 passing dbt models/tests.

### 4. Build metadata foundation
Run the scripts under `metadata/`.

This creates and populates the governance metadata store, dictionary metadata, glossary mappings, CDE registry, tag taxonomy and metadata harvest process.

The implementation uses both `INFORMATION_SCHEMA` and `ACCOUNT_USAGE`. `INFORMATION_SCHEMA` is used for immediate validation where Account Usage latency would delay evidence.

### 5. Run classification
Run the committed scripts under `classification/`.

The implementation includes a Snowflake classification profile, automatic classification on STAGING, a custom classifier, sealed-list comparison, precision/recall calculation, steward approval/rejection workflow, and synchronization of confirmed classifications to the `CLASSIFICATION` tag.

Current sealed-list evaluation:
```text
TP = 7
FP = 1
FN = 5
TN = 36
Precision = 0.875
Recall = 0.5833
```

Misses and false positives are retained as evidence rather than hidden.

### 6. Apply data protection
Run the scripts under `protection/`.

The solution demonstrates clear/partial/masked access across governed roles plus branch-scoped row access.

The sensitive-policy gap report is expected to return zero rows for the final protected sensitive-column set.

### 7. Run the six data-quality dimensions
Run the dbt tests and DQ persistence logic under `quality/` and `dbt/`.

`MART_DEPOSITS` is tested for:
```text
Completeness
Uniqueness
Validity
Consistency
Timeliness
Accuracy
```

Results are persisted to `DQ_RESULT`.

Final CI result:
```text
PASS=44
WARN=0
ERROR=0
SKIP=0
```

### 8. Build lineage
Run the scripts under `lineage/`.

The implementation captures Snowflake native upstream/downstream lineage, column-level lineage, `OBJECT_DEPENDENCIES`, `ACCESS_HISTORY`, a `LINEAGE_EDGE` snapshot, external lineage for Talend and Power BI boundaries, a worked trace for deposit totals, and source-column impact analysis.

Where External Lineage is unavailable in the trial, the external relationships are represented in the committed governance lineage store.

### 9. Certification and scorecard
Run the scripts under `certification/`.

`CERTIFY(object)` evaluates evidence rather than assigning certification unconditionally.

The certified deposit mart is evaluated against:
```text
OWNED
DEFINED
TRACEABLE
TRUSTED
SECURE
ADOPTED
RECONCILED
```

`MART_DEPOSITS` currently achieves a 7/7 score when all required evidence checks pass.

### 10. Deploy the Streamlit catalog
The Streamlit application is deployed in Snowflake and reads from the governance metadata store.

It exposes searchable catalog information including owner, steward, certification, CDE status, classification, descriptions, lineage, quality, usage evidence, scorecard results, worked lineage trace and impact analysis.

## GitHub Actions CI
The repository contains `.github/workflows/ci.yml`.

Pipeline:
```text
SQLFluff lint
    ↓
RSA key-pair Snowflake authentication
    ↓
zero-copy CI source clones
    ↓
dbt build
    ↓
CI validation SQL
    ↓
cleanup of CI schemas
```

The workflow authenticates as `SVC_PIPELINE_USER` with the `SVC_PIPELINE` role and does not run as `ACCOUNTADMIN`.

Secrets are stored in GitHub Actions repository secrets and no private key is committed.

## Important Assumptions and Trial Constraints
This implementation uses a Snowflake Enterprise trial and synthetic data only.

`ACCOUNT_USAGE` can lag, so immediate operational validation uses `INFORMATION_SCHEMA` where appropriate while Account Usage remains part of the governance evidence.

External systems such as Talend and Power BI are represented through committed external-lineage metadata where the trial does not expose the required integration.

Cortex behavior is region/account dependent. Any Cortex-generated description workflow should be interpreted together with the committed approval-queue implementation and evidence captured for the trial.

No final governance outcome is intentionally hard-coded: DQ status, certification and scorecard results are derived from current metadata, policy, lineage and test evidence.

## No Hand-Applied Metadata
The submitted implementation is code-first.

Any Snowflake UI actions used while learning or validating a feature are reproduced in committed SQL/dbt/Python before submission so the final result is rebuildable.

## Evidence
The evidence pack should contain query outputs/screenshots for each assessment block, including setup/source counts, metadata harvest and coverage, 25 CDEs and tag references, classification results and precision/recall, role-based masking, row-access behavior, zero sensitive-policy gaps, six DQ outcomes, lineage, worked trace, impact analysis, CERTIFY success/refusal, seven-word scorecard, Streamlit catalog, and successful GitHub Actions run.

## Block 6
The Block 6 deliverable is maintained separately from this README. It covers the current state and expected impact of relevant Snowflake catalog/metadata capabilities, feature status, impact on Blocks 1–5, external-catalog decision gates, and the top three risks.

## Submission Notes
The final package contains:
```text
repository
evidence pack
Block 6 write-up / slides
HOURS.md
AI_DISCLOSURE.md
10-minute walkthrough recording
```

All credentials, private keys and local configuration files are excluded from source control.
