-- protection/04_create_validation_views.sql
-- Validation views (using audit trail instead of MASKING_POLICY)

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- VIEW 1: MASKING_APPLICATIONS_LOG
-- Which columns had masking applied (from audit trail)
-- ============================================
CREATE OR REPLACE VIEW MASKING_APPLICATIONS_LOG AS
SELECT 
  OBJECT_IDENTIFIER as column_name,
  TAG_VALUE as masking_applied,
  ASSIGNED_AT as applied_at,
  ASSIGNED_BY as applied_by,
  'Active' as masking_status
FROM GOVERNANCE.CATALOG.TAG_ASSIGNMENTS_HISTORY
WHERE TAG_NAME = 'MASKING_APPLIED'
ORDER BY ASSIGNED_AT DESC;

-- ============================================
-- VIEW 2: SENSITIVE_COLUMNS_INVENTORY
-- All sensitive columns from Block 2 classification
-- ============================================
CREATE OR REPLACE VIEW SENSITIVE_COLUMNS_INVENTORY AS
SELECT 
  cm.DATABASE_NAME,
  cm.TABLE_NAME,
  cm.COLUMN_NAME,
  ddr.DETECTED_CLASSIFICATION as sensitivity_level
FROM GOVERNANCE.CATALOG.COLUMN_METADATA cm
INNER JOIN GOVERNANCE.CATALOG.DATA_DISCOVERY_RESULTS ddr
  ON cm.DATABASE_NAME = ddr.DATABASE_NAME
  AND cm.TABLE_NAME = ddr.TABLE_NAME
  AND cm.COLUMN_NAME = ddr.COLUMN_NAME
WHERE ddr.DETECTED_CLASSIFICATION IN ('PII', 'ACCOUNT_DETAILS', 'POTENTIALLY_SENSITIVE')
  AND cm.DATABASE_NAME = 'RAW'
ORDER BY cm.TABLE_NAME, cm.COLUMN_NAME;

-- ============================================
-- VIEW 3: MASKING_COVERAGE
-- Summary of protection coverage
-- ============================================
CREATE OR REPLACE VIEW MASKING_COVERAGE AS
SELECT 
  'Total Sensitive Columns Detected' as metric,
  COUNT(DISTINCT cm.COLUMN_NAME) as count
FROM GOVERNANCE.CATALOG.COLUMN_METADATA cm
INNER JOIN GOVERNANCE.CATALOG.DATA_DISCOVERY_RESULTS ddr
  ON cm.DATABASE_NAME = ddr.DATABASE_NAME
  AND cm.TABLE_NAME = ddr.TABLE_NAME
  AND cm.COLUMN_NAME = ddr.COLUMN_NAME
WHERE ddr.DETECTED_CLASSIFICATION IN ('PII', 'ACCOUNT_DETAILS', 'POTENTIALLY_SENSITIVE')
  AND cm.DATABASE_NAME = 'RAW'
UNION ALL
SELECT 
  'Columns with Masking Applied' as metric,
  COUNT(DISTINCT OBJECT_IDENTIFIER) as count
FROM GOVERNANCE.CATALOG.TAG_ASSIGNMENTS_HISTORY
WHERE TAG_NAME = 'MASKING_APPLIED';

-- ============================================
-- VIEW 4: MASKING_AUDIT_TRAIL
-- Full audit trail of masking actions
-- ============================================
CREATE OR REPLACE VIEW MASKING_AUDIT_TRAIL AS
SELECT 
  OBJECT_IDENTIFIER as column_protected,
  TAG_VALUE as masking_details,
  ASSIGNED_AT as applied_at,
  ASSIGNED_BY as applied_by
FROM GOVERNANCE.CATALOG.TAG_ASSIGNMENTS_HISTORY
WHERE TAG_NAME IN ('MASKING_APPLIED', 'MASKING_ROLLED_BACK')
ORDER BY ASSIGNED_AT DESC;

SELECT '✓ Validation views created' as status;

