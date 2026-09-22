-- ============================================================================
-- BLOCK 3 — TRUST: SIX DATA QUALITY CHECKS
-- Avidia Bank Take-Home Assessment
--
-- Suggested repo path:
--   evidence/block3/00_block3_validation.sql
--
-- Purpose:
--   Read-only validation for the six required DQ dimensions on MART_DEPOSITS.
--   Uses the latest persisted dbt invocation in GOVERNANCE.CATALOG.DQ_RESULT.
-- ============================================================================

USE ROLE DATA_OWNER;
USE WAREHOUSE TRANSFORM_WH;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;


-- ============================================================================
-- 1. Resolve the latest real DQ invocation for MART_DEPOSITS
-- ============================================================================

SET DQ_INVOCATION_ID = (
    SELECT INVOCATION_ID
    FROM GOVERNANCE.CATALOG.DQ_RESULT
    WHERE INVOCATION_ID IS NOT NULL
      AND MART_NAME = 'MART_DEPOSITS'
    GROUP BY INVOCATION_ID
    ORDER BY MAX(EXECUTED_AT) DESC
    LIMIT 1
);


-- ============================================================================
-- 2. SIX-DIMENSION SUMMARY
-- Screenshot: 01_dq_summary.png
--
-- Expected:
--   CHECKS_RECORDED      = 6
--   DIMENSIONS_RECORDED  = 6
--   PASSED               = 6
--   FAILED               = 0
--   ASSESSMENT_RESULT    = PASS
-- ============================================================================

SELECT *
FROM GOVERNANCE.CATALOG.EVIDENCE_DQ_SUMMARY
WHERE INVOCATION_ID = $DQ_INVOCATION_ID;


-- ============================================================================
-- 3. DETAILED RESULTS FOR ALL SIX DIMENSIONS
-- Screenshot: 02_six_dq_results.png
--
-- Required dimensions:
--   COMPLETENESS
--   UNIQUENESS
--   VALIDITY
--   CONSISTENCY
--   TIMELINESS
--   ACCURACY
-- ============================================================================

SELECT
    INVOCATION_ID,
    MART_NAME,
    CHECK_DIMENSION,
    CHECK_TYPE,
    TARGET_TABLE,
    TARGET_COLUMN,
    CHECK_RESULT,
    DBT_STATUS,
    FAILED_ROWS,
    FAILURE_UNIT,
    SNAPSHOT_DATE,
    FAILURE_RELATION,
    EXECUTED_BY,
    EXECUTED_AT,
    DETAILS
FROM GOVERNANCE.CATALOG.DQ_RESULT
WHERE INVOCATION_ID = $DQ_INVOCATION_ID
ORDER BY
    CASE UPPER(CHECK_DIMENSION)
        WHEN 'COMPLETENESS' THEN 1
        WHEN 'UNIQUENESS' THEN 2
        WHEN 'VALIDITY' THEN 3
        WHEN 'CONSISTENCY' THEN 4
        WHEN 'TIMELINESS' THEN 5
        WHEN 'ACCURACY' THEN 6
        ELSE 99
    END;


-- ============================================================================
-- 4. VERIFY EXACTLY ONE RESULT PER DIMENSION
-- Screenshot optional.
-- Expected: ZERO rows.
-- ============================================================================

SELECT
    CHECK_DIMENSION,
    COUNT(*) AS RESULT_COUNT
FROM GOVERNANCE.CATALOG.DQ_RESULT
WHERE INVOCATION_ID = $DQ_INVOCATION_ID
GROUP BY CHECK_DIMENSION
HAVING COUNT(*) <> 1;


-- ============================================================================
-- 5. VERIFY ALL SIX REQUIRED DIMENSIONS ARE PRESENT
-- Screenshot optional.
-- Expected:
--   REQUIRED_DIMENSIONS = 6
--   PRESENT_DIMENSIONS  = 6
--   PASSING_DIMENSIONS  = 6
-- ============================================================================

SELECT
    6 AS REQUIRED_DIMENSIONS,
    COUNT(DISTINCT UPPER(CHECK_DIMENSION)) AS PRESENT_DIMENSIONS,
    COUNT(DISTINCT CASE
        WHEN UPPER(CHECK_RESULT) = 'PASS'
        THEN UPPER(CHECK_DIMENSION)
    END) AS PASSING_DIMENSIONS
FROM GOVERNANCE.CATALOG.DQ_RESULT
WHERE INVOCATION_ID = $DQ_INVOCATION_ID
  AND UPPER(CHECK_DIMENSION) IN (
      'COMPLETENESS',
      'UNIQUENESS',
      'VALIDITY',
      'CONSISTENCY',
      'TIMELINESS',
      'ACCURACY'
  );


-- ============================================================================
-- 6. ACCURACY / GL RECONCILIATION EVIDENCE
-- Screenshot: 03_accuracy_gl_reconciliation.png
--
-- This is the DQ row that proves MART_DEPOSITS reconciles to GL within
-- the implemented tolerance.
-- ============================================================================

SELECT
    INVOCATION_ID,
    CHECK_DIMENSION,
    CHECK_TYPE,
    TARGET_TABLE,
    TARGET_COLUMN,
    CHECK_RESULT,
    FAILED_ROWS,
    SNAPSHOT_DATE,
    DETAILS,
    EXECUTED_AT
FROM GOVERNANCE.CATALOG.DQ_RESULT
WHERE INVOCATION_ID = $DQ_INVOCATION_ID
  AND UPPER(CHECK_DIMENSION) = 'ACCURACY';


-- ============================================================================
-- 7. LATEST DQ EXECUTION HISTORY
-- Supporting evidence that DQ results are persisted, not hard-coded.
-- ============================================================================

SELECT
    INVOCATION_ID,
    COUNT(*) AS RESULT_COUNT,
    COUNT(DISTINCT CHECK_DIMENSION) AS DIMENSION_COUNT,
    COUNT_IF(CHECK_RESULT = 'PASS') AS PASS_COUNT,
    MAX(EXECUTED_AT) AS EXECUTED_AT
FROM GOVERNANCE.CATALOG.DQ_RESULT
WHERE MART_NAME = 'MART_DEPOSITS'
GROUP BY INVOCATION_ID
ORDER BY EXECUTED_AT DESC;


-- ============================================================================
-- END BLOCK 3
-- ============================================================================
