-- ============================================================================
-- BLOCK 2 — CLASSIFICATION AND PROTECTION VALIDATION
-- Avidia Bank Take-Home Assessment
--
-- Suggested repo path:
--   evidence/block2/00_block2_validation.sql
--
-- Purpose:
--   Evidence for:
--   * classification results
--   * precision / recall against sealed list
--   * steward review queue
--   * confirmed CLASSIFICATION tags
--   * tag-based masking
--   * row-access policy
--   * zero sensitive-policy gaps
-- ============================================================================

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;


-- ============================================================================
-- 1. CAPTURED CLASSIFICATION RESULTS
-- Screenshot: 01_classification_results.png
-- ============================================================================

SELECT
    DATABASE_NAME,
    SCHEMA_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    SEMANTIC_CATEGORY,
    PRIVACY_CATEGORY,
    CLASSIFIER_SOURCE,
    APPLY_METHOD,
    CAPTURED_AT
FROM GOVERNANCE.CATALOG.CLASSIFICATION_RESULTS
ORDER BY TABLE_NAME, COLUMN_NAME;


-- ============================================================================
-- 2. PRECISION / RECALL AGAINST SEALED TRUTH SET
-- Screenshot: 02_precision_recall.png
-- ============================================================================

WITH metrics AS (
    SELECT
        COUNT_IF(OUTCOME = 'TP') AS TP,
        COUNT_IF(OUTCOME = 'FP') AS FP,
        COUNT_IF(OUTCOME = 'FN') AS FN,
        COUNT_IF(OUTCOME = 'TN') AS TN
    FROM GOVERNANCE.CATALOG.CLASSIFICATION_EVALUATION
)
SELECT
    TP,
    FP,
    FN,
    TN,
    ROUND(TP::FLOAT / NULLIF(TP + FP, 0), 4) AS PRECISION,
    ROUND(TP::FLOAT / NULLIF(TP + FN, 0), 4) AS RECALL
FROM metrics;


-- Supporting evidence: misses / false positives.
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    EXPECTED_CLASSIFICATION,
    SEMANTIC_CATEGORY,
    PRIVACY_CATEGORY,
    CLASSIFIER_SOURCE,
    OUTCOME,
    REASON
FROM GOVERNANCE.CATALOG.CLASSIFICATION_EVALUATION
WHERE OUTCOME IN ('FN', 'FP')
ORDER BY OUTCOME, TABLE_NAME, COLUMN_NAME;


-- ============================================================================
-- 3. STEWARD REVIEW QUEUE
-- Screenshot: 03_steward_review_queue.png
-- Only approved classifications should drive governance CLASSIFICATION tags.
-- ============================================================================

SELECT
    REVIEW_ID,
    TABLE_NAME,
    COLUMN_NAME,
    DETECTED_SEMANTIC_CATEGORY,
    DETECTED_PRIVACY_CATEGORY,
    CLASSIFIER_SOURCE,
    SUGGESTED_CLASSIFICATION,
    CONFIRMED_CLASSIFICATION,
    REVIEW_STATUS,
    REVIEWED_BY,
    REVIEWED_AT,
    REVIEW_NOTES
FROM GOVERNANCE.CATALOG.CLASSIFICATION_REVIEW_QUEUE
ORDER BY REVIEW_STATUS, TABLE_NAME, COLUMN_NAME;


-- Compact approval/rejection count.
SELECT
    REVIEW_STATUS,
    COUNT(*) AS REVIEW_COUNT
FROM GOVERNANCE.CATALOG.CLASSIFICATION_REVIEW_QUEUE
GROUP BY REVIEW_STATUS
ORDER BY REVIEW_STATUS;


-- ============================================================================
-- 4. CONFIRMED GOVERNANCE CLASSIFICATION TAGS
-- Screenshot: 04_confirmed_classification_tags.png
-- ============================================================================

SELECT
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COLUMN_NAME,
    TAG_NAME,
    TAG_VALUE,
    APPLY_METHOD
FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES
WHERE TAG_DATABASE = 'GOVERNANCE'
  AND TAG_SCHEMA = 'CATALOG'
  AND TAG_NAME = 'CLASSIFICATION'
  AND TAG_VALUE IS NOT NULL
ORDER BY OBJECT_DATABASE, OBJECT_SCHEMA, OBJECT_NAME, COLUMN_NAME;


-- ============================================================================
-- 5. ACTIVE TAG-BASED MASKING POLICIES
-- Screenshot: 05_tag_based_masking_policies.png
-- ============================================================================

SELECT
    POLICY_DB,
    POLICY_SCHEMA,
    POLICY_NAME,
    POLICY_KIND,
    POLICY_STATUS,
    REF_ENTITY_NAME,
    REF_ENTITY_DOMAIN,
    REF_COLUMN_NAME,
    TAG_DATABASE,
    TAG_SCHEMA,
    TAG_NAME
FROM TABLE(
    GOVERNANCE.INFORMATION_SCHEMA.POLICY_REFERENCES(
        REF_ENTITY_NAME => 'GOVERNANCE.CATALOG.CLASSIFICATION',
        REF_ENTITY_DOMAIN => 'TAG'
    )
)
WHERE POLICY_KIND = 'MASKING_POLICY'
ORDER BY POLICY_NAME;


-- ============================================================================
-- 6. MASKING OUTPUT BY ROLE
-- Take one screenshot per role.
-- ============================================================================

-- Screenshot: 06a_owner_clear.png
USE ROLE DATA_OWNER;

SELECT
    TAX_ID,
    DATE_OF_BIRTH,
    EMAIL,
    PHONE
FROM ANALYTICS.STAGING.STG_CUSTOMER
WHERE TAX_ID IS NOT NULL
LIMIT 5;

SELECT
    LOAN_MEMO
FROM ANALYTICS.STAGING.STG_LOAN
WHERE LOAN_MEMO IS NOT NULL
LIMIT 5;


-- Screenshot: 06b_steward_partial.png
USE ROLE DATA_STEWARD;

SELECT
    TAX_ID,
    DATE_OF_BIRTH,
    EMAIL,
    PHONE
FROM ANALYTICS.STAGING.STG_CUSTOMER
WHERE TAX_ID IS NOT NULL
LIMIT 5;

SELECT
    LOAN_MEMO
FROM ANALYTICS.STAGING.STG_LOAN
WHERE LOAN_MEMO IS NOT NULL
LIMIT 5;


-- Screenshot: 06c_analyst_masked.png
USE ROLE DEPOSITS_ANALYST;

SELECT
    TAX_ID,
    DATE_OF_BIRTH,
    EMAIL,
    PHONE
FROM ANALYTICS.STAGING.STG_CUSTOMER
WHERE TAX_ID IS NOT NULL
LIMIT 5;

SELECT
    LOAN_MEMO
FROM ANALYTICS.STAGING.STG_LOAN
WHERE LOAN_MEMO IS NOT NULL
LIMIT 5;


-- ============================================================================
-- 7. ROW ACCESS POLICY REFERENCES
-- Screenshot: 07_row_access_policy.png
-- ============================================================================

USE ROLE DATA_OWNER;

SELECT
    POLICY_DB,
    POLICY_SCHEMA,
    POLICY_NAME,
    POLICY_KIND,
    POLICY_STATUS,
    REF_ENTITY_NAME,
    REF_ENTITY_DOMAIN
FROM TABLE(
    GOVERNANCE.INFORMATION_SCHEMA.POLICY_REFERENCES(
        POLICY_NAME => 'GOVERNANCE.CATALOG.BRANCH_ENTITLEMENT_POLICY'
    )
)
WHERE REF_ENTITY_NAME IN (
    'RAW.PUBLIC.ACCOUNT',
    'ANALYTICS.MARTS.MART_DEPOSITS'
)
ORDER BY REF_ENTITY_NAME;


-- ============================================================================
-- 8. DATA_OWNER SEES ALL BRANCHES
-- Supporting screenshot if needed.
-- ============================================================================

USE ROLE DATA_OWNER;

SELECT
    'RAW.PUBLIC.ACCOUNT' AS OBJECT_NAME,
    BRANCH_CODE,
    COUNT(*) AS ROW_COUNT
FROM RAW.PUBLIC.ACCOUNT
GROUP BY BRANCH_CODE
ORDER BY BRANCH_CODE;

SELECT
    'ANALYTICS.MARTS.MART_DEPOSITS' AS OBJECT_NAME,
    BRANCH_CODE,
    COUNT(*) AS ROW_COUNT
FROM ANALYTICS.MARTS.MART_DEPOSITS
GROUP BY BRANCH_CODE
ORDER BY BRANCH_CODE;


-- ============================================================================
-- 9. BRANCH_HUDSON ROW-LEVEL ACCESS
-- Screenshot: 08_branch_hudson_access.png
-- Expected: only the branch assigned in BRANCH_ENTITLEMENTS (BR_01 in the
-- current assessment setup).
-- ============================================================================

USE ROLE BRANCH_HUDSON;

SELECT
    'RAW.PUBLIC.ACCOUNT' AS OBJECT_NAME,
    BRANCH_CODE,
    COUNT(*) AS ROW_COUNT
FROM RAW.PUBLIC.ACCOUNT
GROUP BY BRANCH_CODE
ORDER BY BRANCH_CODE;

SELECT
    'ANALYTICS.MARTS.MART_DEPOSITS' AS OBJECT_NAME,
    BRANCH_CODE,
    COUNT(*) AS ROW_COUNT
FROM ANALYTICS.MARTS.MART_DEPOSITS
GROUP BY BRANCH_CODE
ORDER BY BRANCH_CODE;


-- ============================================================================
-- 10. SENSITIVE POLICY GAP REPORT
-- Screenshot: 09_sensitive_policy_gap_zero.png
-- Assessment requirement: zero rows.
-- ============================================================================

USE ROLE DATA_OWNER;

SELECT *
FROM GOVERNANCE.CATALOG.SENSITIVE_POLICY_GAPS;

SELECT
    COUNT(*) AS SENSITIVE_POLICY_GAP_COUNT
FROM GOVERNANCE.CATALOG.SENSITIVE_POLICY_GAPS;


-- ============================================================================
-- END BLOCK 2
-- ============================================================================
