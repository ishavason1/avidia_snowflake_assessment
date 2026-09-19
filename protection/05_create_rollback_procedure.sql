-- protection/05_create_rollback_procedure.sql
-- Rollback masking

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- PROCEDURE: ROLLBACK_MASKING_FROM_COLUMN
-- ============================================
CREATE OR REPLACE PROCEDURE ROLLBACK_MASKING_FROM_COLUMN(
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
BEGIN
  
  -- Remove masking policy
  EXECUTE IMMEDIATE 
    'ALTER TABLE ' || p_database || '.' || p_schema || '.' || p_table ||
    ' MODIFY COLUMN ' || p_column || ' UNSET MASKING POLICY';
  
  -- Log rollback
  INSERT INTO GOVERNANCE.CATALOG.TAG_ASSIGNMENTS_HISTORY (
    TAG_NAME, OBJECT_TYPE, OBJECT_IDENTIFIER, TAG_VALUE,
    ASSIGNED_BY, ASSIGNED_AT, HARVEST_ID
  )
  VALUES (
    'MASKING_ROLLED_BACK',
    'COLUMN',
    p_database || '.' || p_schema || '.' || p_table || '.' || p_column,
    'Masking policy removed',
    CURRENT_USER(),
    CURRENT_TIMESTAMP(),
    TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYY_MM_DD_HH24_MI_SS')
  );
  
  RETURN OBJECT_CONSTRUCT(
    'status', 'SUCCESS',
    'message', 'Masking removed from ' || p_column
  );
END;
$$;

SELECT '✓ Rollback procedure created' as status;

