-- metadata/create_metadata_views.sql
-- Create views for querying metadata easily

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- 1. VIEW: All Sensitive Columns
-- ============================================
CREATE OR REPLACE VIEW SENSITIVE_COLUMNS_VIEW AS
SELECT 
  TABLE_NAME,
  COLUMN_NAME,
  COLUMN_DESCRIPTION,
  SENSITIVITY_CLASSIFICATION,
  CASE 
    WHEN SENSITIVITY_CLASSIFICATION IN ('PII', 'ACCOUNT_DETAILS') THEN 'MASKING_REQUIRED'
    ELSE 'REVIEW_NEEDED'
  END as masking_status
FROM DATA_DICTIONARY
WHERE SENSITIVITY_CLASSIFICATION IN ('PII', 'SENSITIVE', 'ACCOUNT_DETAILS', 'POTENTIALLY_SENSITIVE')
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ============================================
-- 2. VIEW: All Critical Data Elements
-- ============================================
CREATE OR REPLACE VIEW CDE_SUMMARY_VIEW AS
SELECT 
  CDE_ID,
  CDE_NAME,
  TABLE_NAME,
  COLUMN_NAME,
  CRITICALITY_LEVEL,
  BUSINESS_OWNER,
  DESCRIPTION
FROM CDE_REGISTRY
ORDER BY CRITICALITY_LEVEL DESC, TABLE_NAME;

-- ============================================
-- 3. VIEW: Glossary Term Coverage
-- ============================================
CREATE OR REPLACE VIEW GLOSSARY_COVERAGE_VIEW AS
SELECT 
  g.TERM_NAME,
  g.DEFINITION,
  COUNT(m.COLUMN_NAME) as column_count,
  LISTAGG(DISTINCT m.TABLE_NAME || '.' || m.COLUMN_NAME, ', ') as mapped_columns
FROM BANKING_GLOSSARY g
LEFT JOIN GLOSSARY_TERM_MAPPINGS m ON g.TERM_ID = m.TERM_ID
GROUP BY g.TERM_ID, g.TERM_NAME, g.DEFINITION
ORDER BY column_count DESC;

-- ============================================
-- 4. VIEW: Documentation Coverage
-- ============================================
CREATE OR REPLACE VIEW DOCUMENTATION_COVERAGE_VIEW AS
SELECT 
  TABLE_NAME,
  COUNT(DISTINCT COLUMN_NAME) as documented_columns,
  ROUND(100.0 * COUNT(DISTINCT COLUMN_NAME) / 
    (SELECT COUNT(DISTINCT COLUMN_NAME) FROM DATA_DICTIONARY dd2 
     WHERE dd2.TABLE_NAME = dd1.TABLE_NAME), 2) as documentation_percentage
FROM DATA_DICTIONARY dd1
GROUP BY TABLE_NAME
ORDER BY documentation_percentage ASC;

-- Verify views created
SELECT 'Views Created:' as status;
SHOW VIEWS IN GOVERNANCE.CATALOG;

SELECT '✓ Metadata views created' as status;
