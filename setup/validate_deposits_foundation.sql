-- Read-only checks. Replace these names with relation_name from root-project dbt ls.
SET mart_relation = 'ANALYTICS.MARTS.MART_DEPOSITS';
SET staged_transactions = 'ANALYTICS.STAGING.STG_TRANSACTION';

-- Must be greater than zero.
SELECT COUNT(*) AS mart_row_count FROM IDENTIFIER($mart_relation);

-- Must return no rows: business key has no date component.
SELECT ACCOUNT_ID, COUNT(*) AS occurrence_count
FROM IDENTIFIER($mart_relation)
GROUP BY ACCOUNT_ID
HAVING ACCOUNT_ID IS NULL OR COUNT(*) > 1;

-- Must be greater than zero after the generator/RAW rebuild.
SELECT COUNT(*) AS staged_transaction_count FROM IDENTIFIER($staged_transactions);

-- Inspect both domains; generated data should contain DEBIT and CREDIT only.
SELECT 'RAW' AS layer, TRANSACTION_TYPE, COUNT(*) AS row_count
FROM RAW.PUBLIC.TRANSACTION GROUP BY TRANSACTION_TYPE
UNION ALL
SELECT 'STAGING', TRANSACTION_TYPE, COUNT(*)
FROM IDENTIFIER($staged_transactions) GROUP BY TRANSACTION_TYPE;

-- Must return no rows, including for NULL transaction types.
SELECT 'RAW' AS layer, TRANSACTION_TYPE, COUNT(*) AS invalid_rows
FROM RAW.PUBLIC.TRANSACTION
WHERE TRANSACTION_TYPE IS NULL OR TRANSACTION_TYPE NOT IN ('DEBIT', 'CREDIT')
GROUP BY TRANSACTION_TYPE
UNION ALL
SELECT 'STAGING', TRANSACTION_TYPE, COUNT(*)
FROM IDENTIFIER($staged_transactions)
WHERE TRANSACTION_TYPE IS NULL OR TRANSACTION_TYPE NOT IN ('DEBIT', 'CREDIT')
GROUP BY TRANSACTION_TYPE;

-- Expect CHECKING/SAVINGS controls for the current source snapshot.
SELECT ACCOUNT_TYPE, AS_OF_DATE, CONTROL_TOTAL, RECORD_COUNT
FROM RAW.PUBLIC.GL_CONTROL
ORDER BY ACCOUNT_TYPE, AS_OF_DATE;

-- No duplicate control keys or missing eligible account-type controls.
SELECT ACCOUNT_TYPE, AS_OF_DATE, COUNT(*) AS occurrence_count
FROM RAW.PUBLIC.GL_CONTROL
GROUP BY ACCOUNT_TYPE, AS_OF_DATE
HAVING COUNT(*) > 1 OR ACCOUNT_TYPE IS NULL OR AS_OF_DATE IS NULL;

SELECT a.ACCOUNT_TYPE
FROM RAW.PUBLIC.ACCOUNT a
WHERE a.STATUS = 'ACTIVE' AND a.ACCOUNT_TYPE IN ('CHECKING', 'SAVINGS')
  AND NOT EXISTS (
    SELECT 1 FROM RAW.PUBLIC.GL_CONTROL g WHERE g.ACCOUNT_TYPE = a.ACCOUNT_TYPE
  )
GROUP BY a.ACCOUNT_TYPE;

-- Must return no rows. Counts detect duplicates that set subtraction would hide.
WITH expected AS (
  SELECT ACCOUNT_ID, ACCOUNT_TYPE, COUNT(*) AS source_rows
  FROM RAW.PUBLIC.ACCOUNT
  WHERE STATUS = 'ACTIVE' AND ACCOUNT_TYPE IN ('CHECKING', 'SAVINGS')
  GROUP BY ACCOUNT_ID, ACCOUNT_TYPE
), actual AS (
  SELECT ACCOUNT_ID, ACCOUNT_TYPE, COUNT(*) AS mart_rows
  FROM IDENTIFIER($mart_relation)
  GROUP BY ACCOUNT_ID, ACCOUNT_TYPE
)
SELECT e.ACCOUNT_ID AS source_account_id, m.ACCOUNT_ID AS mart_account_id,
       e.ACCOUNT_TYPE AS source_type, m.ACCOUNT_TYPE AS mart_type,
       e.source_rows, m.mart_rows
FROM expected e
FULL OUTER JOIN actual m
  ON e.ACCOUNT_ID = m.ACCOUNT_ID AND e.ACCOUNT_TYPE = m.ACCOUNT_TYPE
WHERE e.ACCOUNT_ID IS NULL OR m.ACCOUNT_ID IS NULL
   OR e.source_rows <> 1 OR m.mart_rows <> 1;

-- Must return no rows: selected account attributes still match source eligibility.
SELECT ACCOUNT_ID, STATUS, ACCOUNT_TYPE
FROM IDENTIFIER($mart_relation)
WHERE STATUS IS NULL OR STATUS <> 'ACTIVE'
   OR ACCOUNT_TYPE IS NULL OR ACCOUNT_TYPE NOT IN ('CHECKING', 'SAVINGS');
