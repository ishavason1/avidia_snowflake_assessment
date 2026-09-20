-- lineage/08_impact_analysis.sql
-- Impact analysis for RAW.PUBLIC.ACCOUNT.BRANCH_CODE.
--
-- Prefer true column-level lineage.
-- Fall back to object-level lineage only when no exact BRANCH_CODE
-- column-level starting edge exists.

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;


CREATE OR REPLACE VIEW GOVERNANCE.CATALOG.BRANCH_CODE_IMPACT_ANALYSIS AS

WITH RECURSIVE

----------------------------------------------------------------------
-- Determine whether exact column-level lineage exists for the source.
----------------------------------------------------------------------
column_seed_exists AS (

    SELECT COUNT(*) AS CNT
    FROM GOVERNANCE.CATALOG.LINEAGE_EDGE
    WHERE SOURCE_DATABASE = 'RAW'
      AND SOURCE_SCHEMA = 'PUBLIC'
      AND SOURCE_OBJECT = 'ACCOUNT'
      AND SOURCE_COLUMN = 'BRANCH_CODE'
),


----------------------------------------------------------------------
-- Build the initial seed outside the recursive CTE.
--
-- 1. Prefer exact BRANCH_CODE lineage.
-- 2. Use ACCOUNT object-level lineage only when column lineage is absent.
----------------------------------------------------------------------
seed_edges AS (

    SELECT
        E.TARGET_DATABASE,
        E.TARGET_SCHEMA,
        E.TARGET_OBJECT,
        E.TARGET_OBJECT_DOMAIN,
        E.TARGET_COLUMN,
        1 AS HOP,

        'RAW.PUBLIC.ACCOUNT.BRANCH_CODE'
            || ' -> '
            || COALESCE(
                E.TARGET_DATABASE || '.'
                || E.TARGET_SCHEMA || '.'
                || E.TARGET_OBJECT
                || CASE
                    WHEN E.TARGET_COLUMN IS NOT NULL
                    THEN '.' || E.TARGET_COLUMN
                    ELSE ''
                   END,
                '<unknown>'
            ) AS PATH,

        'COLUMN_LEVEL' AS IMPACT_EVIDENCE_TYPE

    FROM GOVERNANCE.CATALOG.LINEAGE_EDGE AS E

    WHERE E.SOURCE_DATABASE = 'RAW'
      AND E.SOURCE_SCHEMA = 'PUBLIC'
      AND E.SOURCE_OBJECT = 'ACCOUNT'
      AND E.SOURCE_COLUMN = 'BRANCH_CODE'


    UNION ALL


    SELECT
        E.TARGET_DATABASE,
        E.TARGET_SCHEMA,
        E.TARGET_OBJECT,
        E.TARGET_OBJECT_DOMAIN,
        E.TARGET_COLUMN,
        1 AS HOP,

        'RAW.PUBLIC.ACCOUNT.BRANCH_CODE'
            || ' -> '
            || COALESCE(
                E.TARGET_DATABASE || '.'
                || E.TARGET_SCHEMA || '.'
                || E.TARGET_OBJECT
                || CASE
                    WHEN E.TARGET_COLUMN IS NOT NULL
                    THEN '.' || E.TARGET_COLUMN
                    ELSE ''
                   END,
                '<unknown>'
            ) AS PATH,

        'OBJECT_LEVEL_FALLBACK' AS IMPACT_EVIDENCE_TYPE

    FROM GOVERNANCE.CATALOG.LINEAGE_EDGE AS E
    CROSS JOIN column_seed_exists AS C

    WHERE C.CNT = 0
      AND E.SOURCE_DATABASE = 'RAW'
      AND E.SOURCE_SCHEMA = 'PUBLIC'
      AND E.SOURCE_OBJECT = 'ACCOUNT'
      AND E.SOURCE_COLUMN IS NULL
),


----------------------------------------------------------------------
-- Recursive traversal.
--
-- Snowflake recursive CTE now has only:
--   anchor
--   UNION ALL
--   recursive branch
----------------------------------------------------------------------
impact_path (
    TARGET_DATABASE,
    TARGET_SCHEMA,
    TARGET_OBJECT,
    TARGET_OBJECT_DOMAIN,
    TARGET_COLUMN,
    HOP,
    PATH,
    IMPACT_EVIDENCE_TYPE
) AS (

    ------------------------------------------------------------------
    -- Anchor
    ------------------------------------------------------------------
    SELECT
        TARGET_DATABASE,
        TARGET_SCHEMA,
        TARGET_OBJECT,
        TARGET_OBJECT_DOMAIN,
        TARGET_COLUMN,
        HOP,
        PATH,
        IMPACT_EVIDENCE_TYPE
    FROM seed_edges


    UNION ALL


    ------------------------------------------------------------------
    -- Recursive branch
    ------------------------------------------------------------------
    SELECT
        E.TARGET_DATABASE,
        E.TARGET_SCHEMA,
        E.TARGET_OBJECT,
        E.TARGET_OBJECT_DOMAIN,
        E.TARGET_COLUMN,

        P.HOP + 1 AS HOP,

        P.PATH
            || ' -> '
            || COALESCE(
                E.TARGET_DATABASE || '.'
                || E.TARGET_SCHEMA || '.'
                || E.TARGET_OBJECT
                || CASE
                    WHEN E.TARGET_COLUMN IS NOT NULL
                    THEN '.' || E.TARGET_COLUMN
                    ELSE ''
                   END,
                '<unknown>'
            ) AS PATH,

        CASE
            WHEN P.IMPACT_EVIDENCE_TYPE = 'OBJECT_LEVEL_FALLBACK'
                THEN 'OBJECT_LEVEL_FALLBACK'

            WHEN P.TARGET_COLUMN IS NOT NULL
                 AND E.SOURCE_COLUMN = P.TARGET_COLUMN
                THEN 'COLUMN_LEVEL'

            ELSE 'OBJECT_LEVEL_FALLBACK'
        END AS IMPACT_EVIDENCE_TYPE

    FROM impact_path AS P

    JOIN GOVERNANCE.CATALOG.LINEAGE_EDGE AS E
      ON E.SOURCE_DATABASE = P.TARGET_DATABASE
     AND E.SOURCE_SCHEMA = P.TARGET_SCHEMA
     AND E.SOURCE_OBJECT = P.TARGET_OBJECT

     AND (
            (
                P.TARGET_COLUMN IS NOT NULL
                AND E.SOURCE_COLUMN = P.TARGET_COLUMN
            )

            OR

            (
                P.TARGET_COLUMN IS NULL
                AND E.SOURCE_COLUMN IS NULL
            )
         )

    WHERE P.HOP < 5

      -- Avoid simple cycles in the lineage path.
      AND POSITION(
            COALESCE(
                E.TARGET_DATABASE || '.'
                || E.TARGET_SCHEMA || '.'
                || E.TARGET_OBJECT
                || CASE
                    WHEN E.TARGET_COLUMN IS NOT NULL
                    THEN '.' || E.TARGET_COLUMN
                    ELSE ''
                   END,
                '<unknown>'
            )
            IN P.PATH
          ) = 0
),


----------------------------------------------------------------------
-- Resolve owner/steward dynamically from catalog metadata.
----------------------------------------------------------------------
asset_governance AS (

    SELECT
        DATABASE_NAME,
        SCHEMA_NAME,
        TABLE_NAME,

        MAX(DATA_OWNER) AS DATA_OWNER,
        MAX(DATA_STEWARD) AS DATA_STEWARD

    FROM GOVERNANCE.CATALOG.CATALOG_MASTER_VIEW

    GROUP BY
        DATABASE_NAME,
        SCHEMA_NAME,
        TABLE_NAME
)


----------------------------------------------------------------------
-- Final impact-analysis output.
----------------------------------------------------------------------
SELECT DISTINCT

    'RAW.PUBLIC.ACCOUNT.BRANCH_CODE' AS SOURCE_COLUMN,

    P.TARGET_DATABASE,
    P.TARGET_SCHEMA,
    P.TARGET_OBJECT,
    P.TARGET_OBJECT_DOMAIN,

    P.TARGET_COLUMN AS AFFECTED_COLUMN,

    P.HOP,
    P.PATH,

    P.IMPACT_EVIDENCE_TYPE,

    G.DATA_OWNER,
    G.DATA_STEWARD

FROM impact_path AS P

LEFT JOIN asset_governance AS G
  ON G.DATABASE_NAME = P.TARGET_DATABASE
 AND G.SCHEMA_NAME = P.TARGET_SCHEMA
 AND G.TABLE_NAME = P.TARGET_OBJECT
;


----------------------------------------------------------------------
-- Evidence output
----------------------------------------------------------------------
SELECT *
FROM GOVERNANCE.CATALOG.BRANCH_CODE_IMPACT_ANALYSIS
ORDER BY
    HOP,
    TARGET_DATABASE,
    TARGET_SCHEMA,
    TARGET_OBJECT,
    AFFECTED_COLUMN;