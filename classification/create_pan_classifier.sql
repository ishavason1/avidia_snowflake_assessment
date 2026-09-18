-- classification/create_pan_classifier.sql
-- Scan tables for potential Card PANs using Luhn validation

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- PROCEDURE: SCAN_FOR_PANS
-- ============================================
CREATE OR REPLACE PROCEDURE SCAN_FOR_PANS()
RETURNS STRING
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  -- Scan LOAN.LOAN_MEMO for potential PANs (deliberately mislabeled column)
  INSERT INTO PAN_DETECTION_RESULTS (
    PAN_DETECTION_ID, TABLE_NAME, COLUMN_NAME, SAMPLE_VALUE, 
    DETECTED_PAN, LUHN_VALID, CONFIDENCE_SCORE, SCAN_TIMESTAMP
  )
  SELECT 
    'PAN_' || ROW_NUMBER() OVER (ORDER BY LOAN_ID),
    'LOAN',
    'LOAN_MEMO',
    LOAN_MEMO,
    -- Extract potential PAN (digits only, 13-19 chars)
    REGEXP_SUBSTR(LOAN_MEMO, '[0-9]{13,19}'),
    VALIDATE_LUHN(REGEXP_SUBSTR(LOAN_MEMO, '[0-9]{13,19}')),
    CASE 
      WHEN VALIDATE_LUHN(REGEXP_SUBSTR(LOAN_MEMO, '[0-9]{13,19}')) THEN 0.95
      ELSE 0.60
    END,
    CURRENT_TIMESTAMP()
  FROM RAW.PUBLIC.LOAN
  WHERE REGEXP_SUBSTR(LOAN_MEMO, '[0-9]{13,19}') IS NOT NULL
    AND LENGTH(REGEXP_SUBSTR(LOAN_MEMO, '[0-9]{13,19}')) >= 13;

  RETURN 'PAN scan complete';
END;
$$;

-- Run scan
CALL SCAN_FOR_PANS();

-- View results
SELECT 'PAN Detection Results:' as status;
SELECT COUNT(*) as pans_found FROM PAN_DETECTION_RESULTS;

SELECT 'Sample PANs detected:' as status;
SELECT TABLE_NAME, COLUMN_NAME, DETECTED_PAN, LUHN_VALID, CONFIDENCE_SCORE
FROM PAN_DETECTION_RESULTS 
WHERE LUHN_VALID = TRUE
LIMIT 5;

SELECT '✓ PAN classifier executed' as status;
