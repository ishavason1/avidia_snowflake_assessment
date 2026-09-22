-- ============================================================================
-- BLOCK 0 — SETUP AND DATA VALIDATION
-- Purpose: evidence queries for environment, source counts,
-- RAW -> STAGING -> MARTS objects, and sealed sensitive list.
-- ============================================================================

USE ROLE DATA_OWNER;

-- --------------------------------------------------------------------------
-- 1. Environment identity
-- Screenshot: account / region / role / warehouse
-- --------------------------------------------------------------------------

SELECT
    CURRENT_ACCOUNT()   AS ACCOUNT,
    CURRENT_REGION()    AS REGION,
    CURRENT_USER()      AS USER_NAME,
    CURRENT_ROLE()      AS ROLE_NAME,
    CURRENT_WAREHOUSE() AS WAREHOUSE_NAME;


-- --------------------------------------------------------------------------
-- 2. Customer count
-- Assessment requirement: >= 3,000 customers
-- Screenshot this result
-- --------------------------------------------------------------------------

SELECT
    COUNT(*) AS RAW_CUSTOMER_COUNT
FROM RAW.PUBLIC.CUSTOMER;


-- --------------------------------------------------------------------------
-- 3. RAW source row counts
-- Shows all main synthetic banking datasets are populated
-- --------------------------------------------------------------------------

SELECT 'CUSTOMER' AS OBJECT_NAME, COUNT(*) AS ROW_COUNT
FROM RAW.PUBLIC.CUSTOMER

UNION ALL

SELECT 'ACCOUNT', COUNT(*)
FROM RAW.PUBLIC.ACCOUNT

UNION ALL

SELECT 'TRANSACTION', COUNT(*)
FROM RAW.PUBLIC.TRANSACTION

UNION ALL

SELECT 'LOAN', COUNT(*)
FROM RAW.PUBLIC.LOAN

UNION ALL

SELECT 'GL_CONTROL', COUNT(*)
FROM RAW.PUBLIC.GL_CONTROL

UNION ALL

SELECT 'BRANCH', COUNT(*)
FROM RAW.PUBLIC.BRANCH

UNION ALL

SELECT 'PRODUCT', COUNT(*)
FROM RAW.PUBLIC.PRODUCT

ORDER BY OBJECT_NAME;


-- --------------------------------------------------------------------------
-- 4. RAW -> STAGING -> MARTS object inventory
-- Assessment requires >=20 objects across the solution
-- --------------------------------------------------------------------------

WITH objects AS (

    SELECT
        'RAW' AS LAYER,
        TABLE_CATALOG AS DATABASE_NAME,
        TABLE_SCHEMA AS SCHEMA_NAME,
        TABLE_NAME,
        TABLE_TYPE
    FROM RAW.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'PUBLIC'

    UNION ALL

    SELECT
        'STAGING',
        TABLE_CATALOG,
        TABLE_SCHEMA,
        TABLE_NAME,
        TABLE_TYPE
    FROM ANALYTICS.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'STAGING'

    UNION ALL

    SELECT
        'MARTS',
        TABLE_CATALOG,
        TABLE_SCHEMA,
        TABLE_NAME,
        TABLE_TYPE
    FROM ANALYTICS.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'MARTS'
)

SELECT *
FROM objects
ORDER BY LAYER, DATABASE_NAME, SCHEMA_NAME, TABLE_NAME;


-- --------------------------------------------------------------------------
-- 5. Object count by layer
-- Easier screenshot for proving total object count
-- --------------------------------------------------------------------------

WITH objects AS (

    SELECT 'RAW' AS LAYER, TABLE_NAME
    FROM RAW.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'PUBLIC'

    UNION ALL

    SELECT 'STAGING', TABLE_NAME
    FROM ANALYTICS.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'STAGING'

    UNION ALL

    SELECT 'MARTS', TABLE_NAME
    FROM ANALYTICS.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'MARTS'
)

SELECT
    LAYER,
    COUNT(*) AS OBJECT_COUNT
FROM objects
GROUP BY LAYER

UNION ALL

SELECT
    'TOTAL',
    COUNT(*)
FROM objects

ORDER BY LAYER;


-- --------------------------------------------------------------------------
-- 6. Sealed sensitive list loaded
-- Shows sensitive truth set existed before classifier evaluation
-- --------------------------------------------------------------------------

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    EXPECTED_CLASSIFICATION,
    SOURCE_SECTION,
    REASON
FROM GOVERNANCE.CATALOG.SEALED_SENSITIVE_COLUMNS
ORDER BY TABLE_NAME, COLUMN_NAME;