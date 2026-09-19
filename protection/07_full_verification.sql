-- protection/07_full_verification.sql
-- Complete verification

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

SELECT '✓✓✓ BLOCK 3 VERIFICATION ✓✓✓' as final_check;

SELECT 'CHECK 1: Masking applications log' as check_name;
SELECT COUNT(*) as count FROM MASKING_APPLICATIONS_LOG;

SELECT 'CHECK 2: Sensitive columns inventory' as check_name;
SELECT COUNT(*) as count FROM SENSITIVE_COLUMNS_INVENTORY;

SELECT 'CHECK 3: Masking coverage summary' as check_name;
SELECT * FROM MASKING_COVERAGE;

SELECT 'CHECK 4: Masking audit trail' as check_name;
SELECT COUNT(*) as count FROM MASKING_AUDIT_TRAIL;

SELECT 'CHECK 5: Evidence protection architecture' as check_name;
SELECT COUNT(*) as count FROM EVIDENCE_PROTECTION_ARCHITECTURE;

SELECT 'CHECK 6: Evidence masking policy mapping' as check_name;
SELECT COUNT(*) as count FROM EVIDENCE_MASKING_POLICY_MAPPING;

SELECT 'CHECK 7: Evidence live demo readiness' as check_name;
SELECT COUNT(*) as count FROM EVIDENCE_LIVE_DEMO_READINESS;

SELECT '✓✓✓ BLOCK 3 COMPLETE ✓✓✓' as final_status;

