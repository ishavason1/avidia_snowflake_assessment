-- classification/create_classification_exceptions.sql
-- Identify and log classification exceptions

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- POPULATE CLASSIFICATION EXCEPTIONS
-- ============================================
INSERT INTO CLASSIFICATION_EXCEPTIONS (
  EXCEPTION_ID, TABLE_NAME, COLUMN_NAME, 
  SEALED_CLASSIFICATION, DETECTED_CLASSIFICATION,
  EXCEPTION_TYPE, SEVERITY, DESCRIPTION
)
SELECT 
  'EXC_' || ROW_NUMBER() OVER (ORDER BY a.TABLE_NAME, a.COLUMN_NAME),
  a.TABLE_NAME,
  a.COLUMN_NAME,
  a.sealed_class,
  a.detected_class,
  a.accuracy_status as EXCEPTION_TYPE,
  CASE 
    WHEN a.sealed_class IN ('PII', 'ACCOUNT_DETAILS') AND a.detected_class IS NULL THEN 'CRITICAL'
    WHEN a.sealed_class IN ('PII', 'ACCOUNT_DETAILS') AND a.detected_class NOT IN ('PII', 'ACCOUNT_DETAILS') THEN 'HIGH'
    ELSE 'MEDIUM'
  END as SEVERITY,
  CASE 
    WHEN a.detected_class IS NULL AND a.sealed_class IN ('PII', 'ACCOUNT_DETAILS') 
      THEN 'Sensitive column not detected by classifier'
    WHEN a.detected_class NOT IN ('PII', 'ACCOUNT_DETAILS') AND a.sealed_class IN ('PII', 'ACCOUNT_DETAILS') 
      THEN 'Sensitive column misclassified'
    WHEN a.sealed_class != a.detected_class 
      THEN 'Classification mismatch: ' || a.sealed_class || ' vs ' || a.detected_class
    ELSE 'Unknown exception'
  END
FROM CLASSIFICATION_ACCURACY_VIEW a
WHERE a.accuracy_status != 'MATCH';

-- Summary
SELECT 'Classification Exceptions Summary:' as status;
SELECT 
  SEVERITY,
  COUNT(*) as exception_count
FROM CLASSIFICATION_EXCEPTIONS
GROUP BY SEVERITY
ORDER BY 
  CASE SEVERITY WHEN 'CRITICAL' THEN 1 WHEN 'HIGH' THEN 2 WHEN 'MEDIUM' THEN 3 END;

SELECT 'CRITICAL Exceptions (Must Fix):' as status;
SELECT 
  TABLE_NAME,
  COLUMN_NAME,
  SEALED_CLASSIFICATION,
  DETECTED_CLASSIFICATION,
  DESCRIPTION
FROM CLASSIFICATION_EXCEPTIONS
WHERE SEVERITY = 'CRITICAL'
ORDER BY TABLE_NAME;

SELECT '✓ Classification exceptions identified' as status;
