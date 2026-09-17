-- setup/00_create_roles.sql
-- Run as ACCOUNTADMIN

USE ROLE ACCOUNTADMIN;

-- ========================================
-- 1. CREATE ROLES
-- ========================================

-- DATA_OWNER: Full access, sets policies, owns objects
CREATE ROLE IF NOT EXISTS DATA_OWNER
  COMMENT = 'Data steward - owns objects, applies governance';

-- DATA_STEWARD: Approves classifications, partial visibility
CREATE ROLE IF NOT EXISTS DATA_STEWARD
  COMMENT = 'Governance gatekeeper - approves classifications, quality checks';

-- DEPOSITS_ANALYST: End user - most masked, normal analyst
CREATE ROLE IF NOT EXISTS DEPOSITS_ANALYST
  COMMENT = 'Analyst - can query marts, sees masked sensitive data';

-- BRANCH_HUDSON: Row-access policy test role (only Hudson branch data)
CREATE ROLE IF NOT EXISTS BRANCH_HUDSON
  COMMENT = 'Branch-scoped - only sees Hudson branch data';

-- SVC_PIPELINE: Service user for scheduled tasks (key-pair auth)
CREATE ROLE IF NOT EXISTS SVC_PIPELINE
  COMMENT = 'Service account - runs scheduled tasks (no password auth)';

-- Grant roles to each other for role hierarchy
GRANT ROLE DATA_STEWARD TO ROLE DATA_OWNER;
GRANT ROLE DEPOSITS_ANALYST TO ROLE DATA_OWNER;
GRANT ROLE BRANCH_HUDSON TO ROLE DATA_OWNER;
GRANT ROLE SVC_PIPELINE TO ROLE DATA_OWNER;

-- Grant to your user (so you can test all roles)
GRANT ROLE DATA_OWNER TO USER ISHAVASON;
GRANT ROLE DATA_STEWARD TO USER ISHAVASON;
GRANT ROLE DEPOSITS_ANALYST TO USER ISHAVASON;
GRANT ROLE BRANCH_HUDSON TO USER ISHAVASON;

SHOW ROLES;
