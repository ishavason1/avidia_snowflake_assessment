-- classification/06_run_staging_classification.sql
-- Attach the native classification profile to STAGING
-- and trigger immediate classification for evidence.

USE ROLE DATA_OWNER;
USE WAREHOUSE TRANSFORM_WH;

-- Ongoing automatic classification for the STAGING schema.
ALTER SCHEMA ANALYTICS.STAGING
SET CLASSIFICATION_PROFILE =
    'GOVERNANCE.CATALOG.AVIDIA_CLASSIFICATION_PROFILE';

-- Immediate schema-wide classification.
-- auto_tag here applies Snowflake's recommended SYSTEM classification tags,
-- not our final GOVERNANCE.CATALOG.CLASSIFICATION tag.
CALL SYSTEM$CLASSIFY_SCHEMA(
    'ANALYTICS.STAGING',
    {
        'auto_tag': true,
        'custom_classifiers': [
            'GOVERNANCE.CATALOG.AVIDIA_PAN_CLASSIFIER'
        ]
    }
);

-- Immediate detailed classification for STG_LOAN using the profile.
-- Useful because STG_LOAN contains the deliberately hidden PAN-like values.
CALL SYSTEM$CLASSIFY(
    'ANALYTICS.STAGING.STG_LOAN',
    'GOVERNANCE.CATALOG.AVIDIA_CLASSIFICATION_PROFILE'
);