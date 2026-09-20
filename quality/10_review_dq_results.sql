-- Read-only evidence for the latest persisted assessment execution.
USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

SET dq_invocation_id = (
  SELECT INVOCATION_ID FROM DQ_RESULT
  WHERE INVOCATION_ID IS NOT NULL AND MART_NAME = 'MART_DEPOSITS'
  GROUP BY INVOCATION_ID
  ORDER BY MAX(EXECUTED_AT) DESC
  LIMIT 1
);

SELECT * FROM EVIDENCE_DQ_SUMMARY
WHERE INVOCATION_ID = $dq_invocation_id;

SELECT INVOCATION_ID, CHECK_DIMENSION, CHECK_RESULT, DBT_STATUS,
       FAILED_ROWS, FAILURE_UNIT, SNAPSHOT_DATE, FAILURE_RELATION,
       EXECUTED_AT, EXECUTED_BY, DETAILS
FROM DQ_RESULT
WHERE INVOCATION_ID = $dq_invocation_id
ORDER BY CHECK_DIMENSION;

-- Must return no rows: one result per dimension in this execution.
SELECT CHECK_DIMENSION, COUNT(*) AS result_count
FROM DQ_RESULT
WHERE INVOCATION_ID = $dq_invocation_id
GROUP BY CHECK_DIMENSION
HAVING COUNT(*) <> 1;

-- History remains visible; NULL invocation IDs are legacy/unverified records.
SELECT INVOCATION_ID, COUNT(*) AS result_count, MAX(EXECUTED_AT) AS executed_at
FROM DQ_RESULT
GROUP BY INVOCATION_ID
ORDER BY executed_at DESC;

-- For latest-run drill-down, use a non-NULL FAILURE_RELATION returned above.
-- These dbt tables are replaced on subsequent test executions; they are not
-- historical failure snapshots. The persisted counts retain execution history.
