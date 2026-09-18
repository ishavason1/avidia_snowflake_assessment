-- metadata/create_tag_taxonomy.sql
-- Create Snowflake tag taxonomy for governance

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- CREATE TAGS (Simplified - no ALLOWED_VALUES)
-- ============================================

CREATE TAG IF NOT EXISTS DOMAIN 
  COMMENT = 'Business domain: CUSTOMER, DEPOSIT, LOAN, REFERENCE, GL';

CREATE TAG IF NOT EXISTS LAYER 
  COMMENT = 'Data layer: RAW, STAGING, MARTS, INTERMEDIATE';

CREATE TAG IF NOT EXISTS CERTIFICATION 
  COMMENT = 'Certification level: CERTIFIED, IN_PROGRESS, UNDER_REVIEW, NOT_CERTIFIED';

CREATE TAG IF NOT EXISTS DATA_OWNER 
  COMMENT = 'Owner of the data asset';

CREATE TAG IF NOT EXISTS DATA_STEWARD 
  COMMENT = 'Data steward responsible for quality/definitions';

CREATE TAG IF NOT EXISTS CDE 
  COMMENT = 'Is this a Critical Data Element? (YES/NO)';

CREATE TAG IF NOT EXISTS CDE_TIER 
  COMMENT = 'Tier level for CDE: 1 (highest), 2, 3';

CREATE TAG IF NOT EXISTS CLASSIFICATION 
  COMMENT = 'Data sensitivity: PUBLIC, INTERNAL, SENSITIVE, PII, ACCOUNT_DETAILS';

CREATE TAG IF NOT EXISTS SOURCE_SYSTEM 
  COMMENT = 'Source system that generated the data';

CREATE TAG IF NOT EXISTS LAST_CERTIFIED 
  COMMENT = 'Timestamp of last certification';

CREATE TAG IF NOT EXISTS MASKING_REQUIRED 
  COMMENT = 'Does this column need masking? (YES/NO)';

-- Verify tags created
SELECT 'Tags Created Successfully:' as status;
SHOW TAGS IN DATABASE GOVERNANCE;

SELECT '✓ Tag taxonomy created' as status;
