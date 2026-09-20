-- classification/07_capture_classification_results.sql
-- Capture Snowflake native/custom classification results from STAGING.

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

CREATE TABLE IF NOT EXISTS CLASSIFICATION_RESULTS (
    DATABASE_NAME VARCHAR,
    SCHEMA_NAME VARCHAR,
    TABLE_NAME VARCHAR,
    COLUMN_NAME VARCHAR,
    SEMANTIC_CATEGORY VARCHAR,
    PRIVACY_CATEGORY VARCHAR,
    CLASSIFIER_SOURCE VARCHAR,
    APPLY_METHOD VARCHAR,
    CAPTURED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (
        DATABASE_NAME,
        SCHEMA_NAME,
        TABLE_NAME,
        COLUMN_NAME
    )
);

-- Refresh current staging classification snapshot.
DELETE FROM CLASSIFICATION_RESULTS
WHERE DATABASE_NAME = 'ANALYTICS'
  AND SCHEMA_NAME = 'STAGING';

-- STG_ACCOUNT
INSERT INTO CLASSIFICATION_RESULTS (
    DATABASE_NAME,
    SCHEMA_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    SEMANTIC_CATEGORY,
    PRIVACY_CATEGORY,
    CLASSIFIER_SOURCE,
    APPLY_METHOD
)
SELECT
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COLUMN_NAME,

    MAX(
        CASE
            WHEN LOWER(TAG_NAME) = 'semantic_category'
            THEN TAG_VALUE
        END
    ) AS SEMANTIC_CATEGORY,

    MAX(
        CASE
            WHEN LOWER(TAG_NAME) = 'privacy_category'
            THEN TAG_VALUE
        END
    ) AS PRIVACY_CATEGORY,

    CASE
        WHEN MAX(
            CASE
                WHEN LOWER(TAG_NAME) = 'semantic_category'
                 AND TAG_VALUE = 'CARD_PAN'
                THEN 1
                ELSE 0
            END
        ) = 1
        THEN 'AVIDIA_PAN_CLASSIFIER'
        ELSE 'SNOWFLAKE_NATIVE'
    END AS CLASSIFIER_SOURCE,

    MAX(APPLY_METHOD)

FROM TABLE(
    ANALYTICS.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
        'ANALYTICS.STAGING.STG_ACCOUNT',
        'TABLE'
    )
)
WHERE LOWER(TAG_NAME) IN (
    'semantic_category',
    'privacy_category'
)
GROUP BY
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COLUMN_NAME;

-- STG_CUSTOMER
INSERT INTO CLASSIFICATION_RESULTS
SELECT
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COLUMN_NAME,

    MAX(
        CASE
            WHEN LOWER(TAG_NAME) = 'semantic_category'
            THEN TAG_VALUE
        END
    ),

    MAX(
        CASE
            WHEN LOWER(TAG_NAME) = 'privacy_category'
            THEN TAG_VALUE
        END
    ),

    CASE
        WHEN MAX(
            CASE
                WHEN LOWER(TAG_NAME) = 'semantic_category'
                 AND TAG_VALUE = 'CARD_PAN'
                THEN 1
                ELSE 0
            END
        ) = 1
        THEN 'AVIDIA_PAN_CLASSIFIER'
        ELSE 'SNOWFLAKE_NATIVE'
    END,

    MAX(APPLY_METHOD),
    CURRENT_TIMESTAMP()

FROM TABLE(
    ANALYTICS.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
        'ANALYTICS.STAGING.STG_CUSTOMER',
        'TABLE'
    )
)
WHERE LOWER(TAG_NAME) IN (
    'semantic_category',
    'privacy_category'
)
GROUP BY
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COLUMN_NAME;

-- STG_LOAN
INSERT INTO CLASSIFICATION_RESULTS
SELECT
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COLUMN_NAME,

    MAX(
        CASE
            WHEN LOWER(TAG_NAME) = 'semantic_category'
            THEN TAG_VALUE
        END
    ),

    MAX(
        CASE
            WHEN LOWER(TAG_NAME) = 'privacy_category'
            THEN TAG_VALUE
        END
    ),

    CASE
        WHEN MAX(
            CASE
                WHEN LOWER(TAG_NAME) = 'semantic_category'
                 AND TAG_VALUE = 'CARD_PAN'
                THEN 1
                ELSE 0
            END
        ) = 1
        THEN 'AVIDIA_PAN_CLASSIFIER'
        ELSE 'SNOWFLAKE_NATIVE'
    END,

    MAX(APPLY_METHOD),
    CURRENT_TIMESTAMP()

FROM TABLE(
    ANALYTICS.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
        'ANALYTICS.STAGING.STG_LOAN',
        'TABLE'
    )
)
WHERE LOWER(TAG_NAME) IN (
    'semantic_category',
    'privacy_category'
)
GROUP BY
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COLUMN_NAME;

-- STG_TRANSACTION
INSERT INTO CLASSIFICATION_RESULTS
SELECT
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COLUMN_NAME,

    MAX(
        CASE
            WHEN LOWER(TAG_NAME) = 'semantic_category'
            THEN TAG_VALUE
        END
    ),

    MAX(
        CASE
            WHEN LOWER(TAG_NAME) = 'privacy_category'
            THEN TAG_VALUE
        END
    ),

    CASE
        WHEN MAX(
            CASE
                WHEN LOWER(TAG_NAME) = 'semantic_category'
                 AND TAG_VALUE = 'CARD_PAN'
                THEN 1
                ELSE 0
            END
        ) = 1
        THEN 'AVIDIA_PAN_CLASSIFIER'
        ELSE 'SNOWFLAKE_NATIVE'
    END,

    MAX(APPLY_METHOD),
    CURRENT_TIMESTAMP()

FROM TABLE(
    ANALYTICS.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
        'ANALYTICS.STAGING.STG_TRANSACTION',
        'TABLE'
    )
)
WHERE LOWER(TAG_NAME) IN (
    'semantic_category',
    'privacy_category'
)
GROUP BY
    OBJECT_DATABASE,
    OBJECT_SCHEMA,
    OBJECT_NAME,
    COLUMN_NAME;

SELECT *
FROM CLASSIFICATION_RESULTS
ORDER BY TABLE_NAME, COLUMN_NAME;