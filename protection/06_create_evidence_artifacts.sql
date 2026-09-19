-- protection/06_create_evidence_artifacts.sql
-- Evidence for review

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- EVIDENCE VIEW 1: PROTECTION_ARCHITECTURE
-- ============================================
CREATE OR REPLACE VIEW EVIDENCE_PROTECTION_ARCHITECTURE AS
SELECT 
  'Block 2 Detection' as stage,
  'Unconfirmed classifications identified' as description
UNION ALL
SELECT 
  'Block 2 Steward Review',
  'Steward confirms classification'
UNION ALL
SELECT 
  'Block 3 Dynamic Protection',
  'Confirmed classifications trigger masking policies'
UNION ALL
SELECT 
  'Block 3 Role-Based Access',
  'Different roles see different data based on policy';

-- ============================================
-- EVIDENCE VIEW 2: MASKING_POLICY_MAPPING
-- ============================================
CREATE OR REPLACE VIEW EVIDENCE_MASKING_POLICY_MAPPING AS
SELECT 
  'PII' as classification,
  'PII_MASK' as policy_name,
  'EMAIL, PHONE, TAX_ID, DOB' as example_columns
UNION ALL
SELECT 
  'ACCOUNT_DETAILS',
  'ACCOUNT_DETAILS_MASK',
  'ACCOUNT_NUMBER'
UNION ALL
SELECT 
  'POTENTIALLY_SENSITIVE',
  'POTENTIALLY_SENSITIVE_MASK',
  'LOAN_MEMO, TRANSACTION.MEMO';

-- ============================================
-- EVIDENCE VIEW 3: LIVE_DEMO_READINESS
-- ============================================
CREATE OR REPLACE VIEW EVIDENCE_LIVE_DEMO_READINESS AS
SELECT 
  1 as step,
  'New Column Added' as action,
  'User adds CUSTOMER.RISK_SCORE' as example
UNION ALL
SELECT 
  2,
  'Block 2 Detection',
  'Discovery identifies column'
UNION ALL
SELECT 
  3,
  'Steward Approval',
  'Tags column as SENSITIVE'
UNION ALL
SELECT 
  4,
  'Block 3 Auto-Protection',
  'Procedure applies POTENTIALLY_SENSITIVE_MASK'
UNION ALL
SELECT 
  5,
  'Validation',
  'View shows column is protected'
UNION ALL
SELECT 
  6,
  'Continue to Block 4-7',
  'Quality, lineage, certification flow';

SELECT '✓ Evidence views created' as status;

