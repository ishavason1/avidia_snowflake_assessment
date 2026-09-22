-- ============================================================================
-- BLOCK 4 — LINEAGE VALIDATION
-- Avidia Bank Take-Home Assessment
--
-- Suggested repo path:
--   evidence/block4/00_block4_validation.sql
--
-- Purpose:
--   Read-only evidence for:
--   * native upstream/downstream lineage
--   * column-level lineage
--   * OBJECT_DEPENDENCIES / ACCESS_HISTORY support
--   * external Talend -> Snowflake and Snowflake -> Power BI lineage
--   * LINEAGE_EDGE snapshot
--   * worked trace for total deposits / TOTAL_CREDITS
--   * impact analysis from a source column
-- ============================================================================

USE ROLE DATA_OWNER;
USE WAREHOUSE TRANSFORM_WH;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;


-- ============================================================================
-- 1. LINEAGE VALIDATION SUMMARY
-- Screenshot: 01_lineage_summary.png
-- ============================================================================

SELECT 'native_get_lineage_edges' AS CHECK_NAME, COUNT(*) AS OBSERVED_COUNT
FROM GOVERNANCE.CATALOG.LINEAGE_EDGE
WHERE LINEAGE_SOURCE = 'SNOWFLAKE_GET_LINEAGE'

UNION ALL

SELECT 'mart_upstream_edges', COUNT(*)
FROM GOVERNANCE.CATALOG.LINEAGE_EDGE
WHERE LINEAGE_SOURCE = 'SNOWFLAKE_GET_LINEAGE'
  AND DIRECTION = 'UPSTREAM'

UNION ALL

SELECT 'mart_downstream_edges', COUNT(*)
FROM GOVERNANCE.CATALOG.LINEAGE_EDGE
WHERE LINEAGE_SOURCE = 'SNOWFLAKE_GET_LINEAGE'
  AND DIRECTION = 'DOWNSTREAM'

UNION ALL

SELECT 'native_column_edges', COUNT(*)
FROM GOVERNANCE.CATALOG.LINEAGE_EDGE
WHERE LINEAGE_SOURCE = 'SNOWFLAKE_GET_LINEAGE'
  AND (SOURCE_COLUMN IS NOT NULL OR TARGET_COLUMN IS NOT NULL)

UNION ALL

SELECT 'external_talend_edges', COUNT(*)
FROM GOVERNANCE.CATALOG.LINEAGE_EDGE_EXTERNAL
WHERE SOURCE_SYSTEM = 'TALEND_LEGACY'
  AND REGISTRATION_TYPE = 'EXTERNAL_MANUAL'

UNION ALL

SELECT 'external_power_bi_edges', COUNT(*)
FROM GOVERNANCE.CATALOG.LINEAGE_EDGE_EXTERNAL
WHERE TARGET_SYSTEM = 'POWER_BI'
  AND REGISTRATION_TYPE = 'EXTERNAL_MANUAL'

UNION ALL

SELECT 'total_credits_trace_raw_inputs', COUNT(*)
FROM GOVERNANCE.CATALOG.TOTAL_CREDITS_LINEAGE_TRACE
WHERE SOURCE_DATABASE = 'RAW'
  AND SOURCE_SCHEMA = 'PUBLIC'
  AND SOURCE_OBJECT = 'TRANSACTION'
  AND SOURCE_COLUMN IN ('AMOUNT', 'TRANSACTION_TYPE')

UNION ALL

SELECT 'branch_code_downstream_impacts', COUNT(*)
FROM GOVERNANCE.CATALOG.BRANCH_CODE_IMPACT_ANALYSIS;


-- ============================================================================
-- 2. NATIVE UPSTREAM / DOWNSTREAM LINEAGE FOR MART_DEPOSITS
-- Screenshot: 02_native_lineage_edges.png
-- ============================================================================

SELECT
    DIRECTION,
    SOURCE_DATABASE,
    SOURCE_SCHEMA,
    SOURCE_OBJECT,
    SOURCE_OBJECT_DOMAIN,
    SOURCE_COLUMN,
    TARGET_DATABASE,
    TARGET_SCHEMA,
    TARGET_OBJECT,
    TARGET_OBJECT_DOMAIN,
    TARGET_COLUMN,
    DISTANCE,
    LINEAGE_SOURCE,
    CAPTURED_AT
FROM GOVERNANCE.CATALOG.LINEAGE_EDGE
WHERE LINEAGE_SOURCE = 'SNOWFLAKE_GET_LINEAGE'
  AND (
       TARGET_OBJECT = 'MART_DEPOSITS'
       OR SOURCE_OBJECT = 'MART_DEPOSITS'
  )
ORDER BY
    DIRECTION,
    DISTANCE,
    SOURCE_DATABASE,
    SOURCE_SCHEMA,
    SOURCE_OBJECT,
    TARGET_OBJECT;


-- ============================================================================
-- 3. COLUMN-LEVEL LINEAGE INTO MART_DEPOSITS
-- Screenshot: 03_column_lineage.png
-- ============================================================================

SELECT
    SOURCE_DATABASE,
    SOURCE_SCHEMA,
    SOURCE_OBJECT,
    SOURCE_COLUMN,
    TARGET_DATABASE,
    TARGET_SCHEMA,
    TARGET_OBJECT,
    TARGET_COLUMN,
    DISTANCE,
    LINEAGE_SOURCE
FROM GOVERNANCE.CATALOG.LINEAGE_EDGE
WHERE LINEAGE_SOURCE = 'SNOWFLAKE_GET_LINEAGE'
  AND TARGET_DATABASE = 'ANALYTICS'
  AND TARGET_SCHEMA = 'MARTS'
  AND TARGET_OBJECT = 'MART_DEPOSITS'
  AND (
      SOURCE_COLUMN IS NOT NULL
      OR TARGET_COLUMN IS NOT NULL
  )
ORDER BY
    TARGET_COLUMN,
    DISTANCE,
    SOURCE_OBJECT,
    SOURCE_COLUMN;


-- ============================================================================
-- 4. EXTERNAL LINEAGE
-- Talend is represented upstream of RAW.
-- Power BI is represented downstream of MART_DEPOSITS.
-- Screenshot: 04_external_lineage.png
-- ============================================================================

SELECT *
FROM GOVERNANCE.CATALOG.LINEAGE_EDGE_EXTERNAL
WHERE SOURCE_SYSTEM = 'TALEND_LEGACY'
   OR TARGET_SYSTEM = 'POWER_BI'
ORDER BY
    SOURCE_SYSTEM,
    TARGET_SYSTEM,
    SOURCE_OBJECT,
    TARGET_OBJECT;


-- ============================================================================
-- 5. WORKED TRACE — TOTAL DEPOSITS / TOTAL_CREDITS
-- Screenshot: 05_total_deposits_trace.png
--
-- The implementation traces TOTAL_CREDITS back through STG_TRANSACTION
-- to RAW.PUBLIC.TRANSACTION.AMOUNT and TRANSACTION_TYPE.
-- ============================================================================

SELECT
    EVIDENCE_TYPE,
    SOURCE_DATABASE,
    SOURCE_SCHEMA,
    SOURCE_OBJECT,
    SOURCE_COLUMN,
    TARGET_DATABASE,
    TARGET_SCHEMA,
    TARGET_OBJECT,
    TARGET_COLUMN,
    DISTANCE,
    EVIDENCE_NOTE
FROM GOVERNANCE.CATALOG.TOTAL_CREDITS_LINEAGE_TRACE
ORDER BY
    EVIDENCE_TYPE,
    DISTANCE,
    SOURCE_DATABASE,
    SOURCE_SCHEMA,
    SOURCE_OBJECT,
    SOURCE_COLUMN;


-- ============================================================================
-- 6. IMPACT ANALYSIS — RAW.PUBLIC.ACCOUNT.BRANCH_CODE
-- Screenshot: 06_impact_analysis.png
--
-- Shows affected downstream objects/columns and owner/steward where resolved.
-- ============================================================================

SELECT
    SOURCE_COLUMN,
    TARGET_DATABASE,
    TARGET_SCHEMA,
    TARGET_OBJECT,
    TARGET_OBJECT_DOMAIN,
    AFFECTED_COLUMN,
    HOP,
    IMPACT_EVIDENCE_TYPE,
    DATA_OWNER,
    DATA_STEWARD,
    PATH
FROM GOVERNANCE.CATALOG.BRANCH_CODE_IMPACT_ANALYSIS
ORDER BY
    HOP,
    TARGET_DATABASE,
    TARGET_SCHEMA,
    TARGET_OBJECT,
    AFFECTED_COLUMN;


-- ============================================================================
-- 7. LINEAGE SNAPSHOT TASK
-- Screenshot: 07_lineage_task.png
-- ============================================================================

SHOW TASKS LIKE 'REFRESH_LINEAGE_SNAPSHOT_TASK'
IN SCHEMA GOVERNANCE.CATALOG;


-- ============================================================================
-- 8. LINEAGE SNAPSHOT TABLE FRESHNESS
-- Optional supporting screenshot.
-- ============================================================================

SELECT
    LINEAGE_SOURCE,
    DIRECTION,
    COUNT(*) AS EDGE_COUNT,
    MAX(CAPTURED_AT) AS LAST_CAPTURED_AT
FROM GOVERNANCE.CATALOG.LINEAGE_EDGE
GROUP BY
    LINEAGE_SOURCE,
    DIRECTION
ORDER BY
    LINEAGE_SOURCE,
    DIRECTION;


-- ============================================================================
-- 9. OBJECT_DEPENDENCIES SUPPORTING EVIDENCE
-- May legitimately return no rows for some transformation patterns.
-- Keep as supporting evidence, not the sole lineage proof.
-- ============================================================================

SELECT
    REFERENCING_DATABASE,
    REFERENCING_SCHEMA,
    REFERENCING_OBJECT_NAME,
    REFERENCING_OBJECT_DOMAIN,
    REFERENCED_DATABASE,
    REFERENCED_SCHEMA,
    REFERENCED_OBJECT_NAME,
    REFERENCED_OBJECT_DOMAIN,
    DEPENDENCY_TYPE
FROM SNOWFLAKE.ACCOUNT_USAGE.OBJECT_DEPENDENCIES
WHERE (
        REFERENCING_DATABASE = 'ANALYTICS'
        AND REFERENCING_SCHEMA = 'MARTS'
        AND REFERENCING_OBJECT_NAME = 'MART_DEPOSITS'
      )
   OR (
        REFERENCED_DATABASE = 'ANALYTICS'
        AND REFERENCED_SCHEMA = 'MARTS'
        AND REFERENCED_OBJECT_NAME = 'MART_DEPOSITS'
      )
ORDER BY
    REFERENCING_DATABASE,
    REFERENCING_SCHEMA,
    REFERENCING_OBJECT_NAME;


-- ============================================================================
-- 10. ACCESS_HISTORY SUPPORTING EVIDENCE
-- Account Usage can lag; this is supplemental to native GET_LINEAGE evidence.
-- ============================================================================

SELECT
    QUERY_ID,
    QUERY_START_TIME,
    USER_NAME,
    DIRECT_OBJECTS_ACCESSED,
    BASE_OBJECTS_ACCESSED
FROM SNOWFLAKE.ACCOUNT_USAGE.ACCESS_HISTORY
WHERE QUERY_START_TIME >= DATEADD('DAY', -7, CURRENT_TIMESTAMP())
  AND (
      DIRECT_OBJECTS_ACCESSED::STRING ILIKE '%MART_DEPOSITS%'
      OR BASE_OBJECTS_ACCESSED::STRING ILIKE '%MART_DEPOSITS%'
  )
ORDER BY QUERY_START_TIME DESC
LIMIT 50;


-- ============================================================================
-- END BLOCK 4
-- ============================================================================
