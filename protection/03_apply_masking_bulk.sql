-- protection/03_apply_masking_bulk.sql
-- Apply masking to all classified columns

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- PROCEDURE: APPLY_MASKING_TO_CONFIRMED_COLUMNS
-- ============================================
CREATE OR REPLACE PROCEDURE APPLY_MASKING_TO_CONFIRMED_COLUMNS()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  v_count INTEGER := 0;
BEGIN
  
  FOR record IN (
    SELECT 
      cm.DATABASE_NAME,
      cm.TABLE_NAME,
      cm.COLUMN_NAME,
      ddr.DETECTED_CLASSIFICATION,
      CASE ddr.DETECTED_CLASSIFICATION
        WHEN 'PII' THEN 'PII_MASK'
        WHEN 'ACCOUNT_DETAILS' THEN 'ACCOUNT_DETAILS_MASK'
        WHEN 'POTENTIALLY_SENSITIVE' THEN 'POTENTIALLY_SENSITIVE_MASK'
        ELSE NULL
      END as policy_name
    FROM GOVERNANCE.CATALOG.COLUMN_METADATA cm
    INNER JOIN GOVERNANCE.CATALOG.DATA_DISCOVERY_RESULTS ddr
      ON cm.DATABASE_NAME = ddr.DATABASE_NAME
      AND cm.TABLE_NAME = ddr.TABLE_NAME
      AND cm.COLUMN_NAME = ddr.COLUMN_NAME
    WHERE ddr.DETECTED_CLASSIFICATION IN ('PII', 'ACCOUNT_DETAILS', 'POTENTIALLY_SENSITIVE')
      AND cm.DATABASE_NAME = 'RAW'
  ) DO
    
    IF (record.policy_name IS NOT NULL) THEN
      BEGIN
        EXECUTE IMMEDIATE 
          'ALTER TABLE ' || record.DATABASE_NAME || '.PUBLIC.' || record.TABLE_NAME ||
          ' MODIFY COLUMN ' || record.COLUMN_NAME ||
          ' SET MASKING POLICY GOVERNANCE.CATALOG.' || record.policy_name;
        
        v_count := v_count + 1;
        
        INSERT INTO GOVERNANCE.CATALOG.TAG_ASSIGNMENTS_HISTORY (
          TAG_NAME, OBJECT_TYPE, OBJECT_IDENTIFIER, TAG_VALUE,
          ASSIGNED_BY, ASSIGNED_AT, HARVEST_ID
        )
        VALUES (
          'MASKING_APPLIED',
          'COLUMN',
          record.DATABASE_NAME || '.PUBLIC.' || record.TABLE_NAME || '.' || record.COLUMN_NAME,
          record.DETECTED_CLASSIFICATION || ' → ' || record.policy_name,
          CURRENT_USER(),
          CURRENT_TIMESTAMP(),
          TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYY_MM_DD_HH24_MI_SS')
        );
      
      EXCEPTION WHEN OTHER THEN
        NULL;
      END;
    END IF;
  
  END FOR;
  
  RETURN 'Masking applied to ' || v_count || ' columns';
END;
$$;

SELECT '✓ Bulk masking procedure created' as status;

