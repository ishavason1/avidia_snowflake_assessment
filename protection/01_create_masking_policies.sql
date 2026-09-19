-- protection/01_create_masking_policies.sql
-- Create masking policies (not applied yet)

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- 1. MASKING POLICY: PII_MASK
-- ============================================
CREATE OR REPLACE MASKING POLICY PII_MASK AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() = 'ACCOUNTADMIN' THEN val
    WHEN CURRENT_ROLE() = 'DATA_OWNER' THEN val
    WHEN CURRENT_ROLE() = 'DATA_STEWARD' THEN val
    ELSE '***MASKED***'
  END;

-- ============================================
-- 2. MASKING POLICY: ACCOUNT_DETAILS_MASK
-- ============================================
CREATE OR REPLACE MASKING POLICY ACCOUNT_DETAILS_MASK AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() = 'ACCOUNTADMIN' THEN val
    WHEN CURRENT_ROLE() = 'DATA_OWNER' THEN val
    WHEN CURRENT_ROLE() = 'DATA_STEWARD' THEN val
    WHEN CURRENT_ROLE() = 'DEPOSITS_ANALYST' THEN val
    ELSE CONCAT(SUBSTRING(val, 1, 2), '***', SUBSTRING(val, -2))
  END;

-- ============================================
-- 3. MASKING POLICY: POTENTIALLY_SENSITIVE_MASK
-- ============================================
CREATE OR REPLACE MASKING POLICY POTENTIALLY_SENSITIVE_MASK AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() = 'ACCOUNTADMIN' THEN val
    WHEN CURRENT_ROLE() = 'DATA_OWNER' THEN val
    WHEN CURRENT_ROLE() = 'DATA_STEWARD' THEN val
    WHEN CURRENT_ROLE() = 'DEPOSITS_ANALYST' THEN val
    ELSE '[SENSITIVE TEXT MASKED]'
  END;

-- ============================================
-- 4. MASKING POLICY: HASH_MASK
-- ============================================
CREATE OR REPLACE MASKING POLICY HASH_MASK AS (val VARCHAR) RETURNS VARCHAR ->
  CASE
    WHEN CURRENT_ROLE() = 'ACCOUNTADMIN' THEN val
    WHEN CURRENT_ROLE() = 'DATA_OWNER' THEN val
    WHEN CURRENT_ROLE() = 'DATA_STEWARD' THEN val
    ELSE MD5(val)
  END;

SELECT '✓ All 4 masking policies created' as validation_result;

