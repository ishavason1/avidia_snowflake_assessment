-- protection/02_create_masking_procedures.sql
-- Parametric procedure to apply masking to a specific column

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- PROCEDURE: APPLY_MASKING_TO_COLUMN
-- ============================================
CREATE OR REPLACE PROCEDURE APPLY_MASKING_TO_COLUMN(
  p_database VARCHAR,
  p_schema VARCHAR,
  p_table VARCHAR,
  p_column VARCHAR
)
RETURNS OBJECT
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  v_classification VARCHAR;
  v_policy VARCHAR;
  v_sql VARCHAR;
BEGIN
  
  -- Step 1: Check if column exists and is classified
  SELECT DETECTED_CLASSIFICATION INTO v_classification
  FROM GOVERNANCE.CATALOG.DATA_DISCOVERY_RESULTS
  WHERE DATABASE_NAME = p_database
    AND TABLE_NAME = p_table
    AND COLUMN_NAME = p_column
  LIMIT 1;
  
  IF (v_classification IS NULL) THEN
    RETURN OBJECT_CONSTRUCT('status', 'ERROR', 'message', 'Column not found or not classified');
  END IF;
  
  -- Step 2: Determine policy
  v_policy := CASE v_classification
    WHEN 'PII' THEN 'GOVERNANCE.CATALOG.PII_MASK'
    WHEN 'ACCOUNT_DETAILS' THEN 'GOVERNANCE.CATALOG.ACCOUNT_DETAILS_MASK'
    WHEN 'POTENTIALLY_SENSITIVE' THEN 'GOVERNANCE.CATALOG.POTENTIALLY_SENSITIVE_MASK'
    ELSE NULL
  END;
  
  IF (v_policy IS NULL) THEN
    RETURN OBJECT_CONSTRUCT('status', 'ERROR', 'message', 'No policy mapped for: ' || v_classification);
  END IF;
  
  -- Step 3: Apply policy
  v_sql := 'ALTER TABLE ' || p_database || '.PUBLIC.' || p_table || 
           ' MODIFY COLUMN ' || p_column || 
           ' SET MASKING POLICY ' || v_policy;
  
  EXECUTE IMMEDIATE v_sql;
  
  -- Step 4: Log
  INSERT INTO GOVERNANCE.CATALOG.TAG_ASSIGNMENTS_HISTORY (
    TAG_NAME, OBJECT_TYPE, OBJECT_IDENTIFIER, TAG_VALUE,
    ASSIGNED_BY, ASSIGNED_AT, HARVEST_ID
  )
  VALUES (
    'MASKING_APPLIED',
    'COLUMN',
    p_database || '.PUBLIC.' || p_table || '.' || p_column,
    v_classification || ' → ' || v_policy,
    CURRENT_USER(),
    CURRENT_TIMESTAMP(),
    TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYY_MM_DD_HH24_MI_SS')
  );
  
  RETURN OBJECT_CONSTRUCT(
    'status', 'SUCCESS',
    'database', p_database,
    'table', p_table,
    'column', p_column,
    'classification', v_classification,
    'policy_applied', v_policy
  );
END;
$$;

SELECT '✓ Parametric procedure created' as status;

