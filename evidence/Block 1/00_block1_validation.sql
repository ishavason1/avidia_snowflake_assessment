-- ============================================================================
-- BLOCK 1 — METADATA FOUNDATION VALIDATION
-- Avidia Bank Take-Home Assessment
--
-- Purpose:
--   Read-only evidence queries for metadata harvest, dictionary coverage,
--   glossary, CDE registry, tag references, owner/steward and tag taxonomy.
--
-- Suggested repo path:
--   evidence/block1/00_block1_validation.sql
-- ============================================================================

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;


-- ============================================================================
-- 1. METADATA HARVEST — TABLE INVENTORY / FRESHNESS
-- Screenshot: block1/01_metadata_harvest.png
-- ============================================================================

SELECT
    DATABASE_NAME,
    COUNT(*) AS TABLE_OBJECTS,
    MAX(HARVESTED_AT) AS LAST_TABLE_HARVEST
FROM GOVERNANCE.CATALOG.TABLE_METADATA
GROUP BY DATABASE_NAME
ORDER BY DATABASE_NAME;


SELECT
    DATABASE_NAME,
    COUNT(*) AS COLUMN_OBJECTS,
    MAX(HARVESTED_AT) AS LAST_COLUMN_HARVEST
FROM GOVERNANCE.CATALOG.COLUMN_METADATA
GROUP BY DATABASE_NAME
ORDER BY DATABASE_NAME;


-- ============================================================================
-- 2. METADATA HARVEST TASK
-- Screenshot: block1/02_metadata_task.png
-- ============================================================================

SHOW TASKS LIKE 'HARVEST_METADATA_TASK'
IN SCHEMA GOVERNANCE.CATALOG;


-- ============================================================================
-- 3. DICTIONARY / DOCUMENTATION COVERAGE
-- Screenshot: block1/03_dictionary_coverage.png
-- ============================================================================

SELECT *
FROM GOVERNANCE.CATALOG.DOCUMENTATION_COVERAGE_VIEW
ORDER BY DOCUMENTATION_PERCENTAGE ASC, TABLE_NAME;


-- Detailed proof for certified mart used later in CERTIFY()
SELECT
    COUNT(*) AS TOTAL_COLUMNS,
    COUNT_IF(
        DESCRIPTION IS NOT NULL
        AND TRIM(DESCRIPTION) <> ''
    ) AS DOCUMENTED_COLUMNS,
    ROUND(
        100.0 * COUNT_IF(
            DESCRIPTION IS NOT NULL
            AND TRIM(DESCRIPTION) <> ''
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS DOCUMENTATION_PERCENTAGE
FROM GOVERNANCE.CATALOG.CATALOG_MASTER_VIEW
WHERE DATABASE_NAME = 'ANALYTICS'
  AND SCHEMA_NAME = 'MARTS'
  AND TABLE_NAME = 'MART_DEPOSITS';


-- ============================================================================
-- 4. BANKING GLOSSARY — 10 TERMS
-- Screenshot: block1/04_glossary_terms.png
-- ============================================================================

SELECT
    TERM_ID,
    TERM_NAME,
    BUSINESS_DOMAIN,
    DEFINITION,
    SYNONYMS
FROM GOVERNANCE.CATALOG.BANKING_GLOSSARY
ORDER BY TERM_ID;


SELECT COUNT(*) AS GLOSSARY_TERM_COUNT
FROM GOVERNANCE.CATALOG.BANKING_GLOSSARY;


-- ============================================================================
-- 5. GLOSSARY → PHYSICAL COLUMN MAPPINGS
-- Screenshot: block1/05_glossary_mappings.png
-- ============================================================================

SELECT
    TERM_NAME,
    DEFINITION,
    COLUMN_COUNT,
    MAPPED_COLUMNS
FROM GOVERNANCE.CATALOG.GLOSSARY_COVERAGE_VIEW
ORDER BY TERM_NAME;


-- ============================================================================
-- 6. CDE REGISTRY — 25 CRITICAL DATA ELEMENTS
-- Screenshot: block1/06_cde_registry.png
-- ============================================================================

SELECT
    CDE_ID,
    CDE_NAME,
    DATABASE_NAME,
    SCHEMA_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    CRITICALITY_LEVEL,
    BUSINESS_OWNER,
    DESCRIPTION
FROM GOVERNANCE.CATALOG.CDE_REGISTRY
ORDER BY CDE_ID;


SELECT COUNT(*) AS REGISTERED_CDE_COUNT
FROM GOVERNANCE.CATALOG.CDE_REGISTRY;


-- ============================================================================
-- 7. LIVE CDE TAG REFERENCES
-- Assessment specifically asks that TAG_REFERENCES alone can list CDEs.
-- Screenshot: block1/07_cde_tag_references.png
--
-- NOTE:
-- ACCOUNT_USAGE can lag. If this is temporarily behind, wait for propagation
-- and keep the screenshot once the current assignments are visible.
-- ============================================================================

SELECT
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COLUMN_NAME,
    TAG_NAME,
    TAG_VALUE,
    APPLY_METHOD
FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES
WHERE TAG_DATABASE = 'GOVERNANCE'
  AND TAG_SCHEMA = 'CATALOG'
  AND TAG_NAME IN ('CDE', 'CDE_TIER')
  AND TAG_VALUE IS NOT NULL
ORDER BY
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COLUMN_NAME,
    TAG_NAME;


-- Count unique CDE-tagged columns.
SELECT
    COUNT(DISTINCT
        OBJECT_DATABASE || '.' ||
        OBJECT_SCHEMA || '.' ||
        OBJECT_NAME || '.' ||
        COALESCE(COLUMN_NAME, '')
    ) AS CDE_TAGGED_COLUMN_COUNT
FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES
WHERE TAG_DATABASE = 'GOVERNANCE'
  AND TAG_SCHEMA = 'CATALOG'
  AND TAG_NAME = 'CDE'
  AND TAG_VALUE = 'YES';


-- ============================================================================
-- 8. OWNER / STEWARD TAG REFERENCES
-- Screenshot: block1/08_owner_steward_tags.png
-- ============================================================================

SELECT
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    MAX(CASE
        WHEN TAG_NAME = 'DATA_OWNER'
        THEN TAG_VALUE
    END) AS DATA_OWNER,
    MAX(CASE
        WHEN TAG_NAME = 'DATA_STEWARD'
        THEN TAG_VALUE
    END) AS DATA_STEWARD
FROM SNOWFLAKE.ACCOUNT_USAGE.TAG_REFERENCES
WHERE TAG_DATABASE = 'GOVERNANCE'
  AND TAG_SCHEMA = 'CATALOG'
  AND TAG_NAME IN ('DATA_OWNER', 'DATA_STEWARD')
GROUP BY
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME
ORDER BY
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME;


-- ============================================================================
-- 9. TAG TAXONOMY EXISTS
-- Screenshot: block1/09_tag_taxonomy.png
-- ============================================================================

SHOW TAGS IN SCHEMA GOVERNANCE.CATALOG;


-- ============================================================================
-- 10. MART_DEPOSITS GOVERNANCE SUMMARY
-- Optional compact screenshot tying Block 1 together.
-- Screenshot: block1/10_mart_deposits_metadata.png
-- ============================================================================

SELECT
    DATABASE_NAME,
    SCHEMA_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    DESCRIPTION,
    CDE_FLAG,
    CRITICALITY_LEVEL,
    DATA_OWNER,
    DATA_STEWARD,
    CERTIFICATION,
    LAST_METADATA_REFRESH
FROM GOVERNANCE.CATALOG.CATALOG_MASTER_VIEW
WHERE DATABASE_NAME = 'ANALYTICS'
  AND SCHEMA_NAME = 'MARTS'
  AND TABLE_NAME = 'MART_DEPOSITS'
ORDER BY ORDINAL_POSITION;


-- ============================================================================
-- END BLOCK 1
-- ============================================================================
