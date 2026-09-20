-- protection/03_bind_masking_policies.sql
-- One tag, one matching masking policy per data type. Approved classification
-- tags are supplied exclusively by classification/10_sync_confirmed_classification_tags.sql.

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

ALTER TAG GOVERNANCE.CATALOG.CLASSIFICATION SET
  MASKING POLICY GOVERNANCE.CATALOG.CLASSIFICATION_MASK_VARCHAR,
  MASKING POLICY GOVERNANCE.CATALOG.CLASSIFICATION_MASK_DATE,
  MASKING POLICY GOVERNANCE.CATALOG.CLASSIFICATION_MASK_NUMBER
  FORCE;

-- Propagate an approved source classification through dbt dependencies and
-- data movement, including into certified marts. This does not create a new
-- manual classification decision.
ALTER TAG GOVERNANCE.CATALOG.CLASSIFICATION SET
  PROPAGATE = ON_DEPENDENCY_AND_DATA_MOVEMENT;
