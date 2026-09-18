-- classification/create_evidence_artifacts.sql
-- Generate evidence for 60-min review

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- EVIDENCE 1: Classification Test Results
-- ============================================
CREATE OR REPLACE VIEW EVIDENCE_CLASSIFICATION_RESULTS AS
SELECT 
  'Classification Detection Test' as evidence_type,
  COUNT(*) as total_columns_tested,
  SUM(CASE WHEN test_result = 'PASS' THEN 1 ELSE 0 END) as columns_pass,
  SUM(CASE WHEN test_result LIKE 'FAIL%' THEN 1 ELSE 0 END) as columns_fail,
  ROUND(100.0 * SUM(CASE WHEN test_result = 'PASS' THEN 1 ELSE 0 END) / 
    COUNT(*), 2) as accuracy_percentage
FROM CLASSIFICATION_ACCURACY_VIEW;

-- ============================================
-- EVIDENCE 2: PAN Detection Results
-- ============================================
CREATE OR REPLACE VIEW EVIDENCE_PAN_DETECTION AS
SELECT 
  'Card PAN Detection (Luhn Validation)' as evidence_type,
  COUNT(*) as total_pans_found,
  SUM(CASE WHEN LUHN_VALID THEN 1 ELSE 0 END) as valid_luhn_cards,
  (SELECT TABLE_NAME FROM PAN_DETECTION_RESULTS LIMIT 1) as table_where_found,
  (SELECT COLUMN_NAME FROM PAN_DETECTION_RESULTS LIMIT 1) as column_where_found,
  'LOAN.LOAN_MEMO (deliberately mislabeled)' as detection_method
FROM PAN_DETECTION_RESULTS;

-- ============================================
-- EVIDENCE 3: Steward Approval Status
-- ============================================
CREATE OR REPLACE VIEW EVIDENCE_APPROVAL_STATUS AS
SELECT 
  'Steward Approval Workflow' as evidence_type,
  APPROVAL_STATUS as status,
  COUNT(*) as count
FROM STEWARD_APPROVAL_QUEUE
GROUP BY APPROVAL_STATUS;

-- Show all evidence
SELECT '✓✓✓ BLOCK 2 EVIDENCE ARTIFACTS ✓✓✓' as section;

SELECT * FROM EVIDENCE_CLASSIFICATION_RESULTS;
SELECT * FROM EVIDENCE_PAN_DETECTION;
SELECT * FROM EVIDENCE_APPROVAL_STATUS;

SELECT '✓ Evidence artifacts created' as status;
