-- setup/05_create_ci_service_user.sql
-- One-time administrative bootstrap for GitHub Actions service identity.
-- Do NOT run this file from GitHub Actions.

USE ROLE ACCOUNTADMIN;

CREATE USER IF NOT EXISTS SVC_PIPELINE_USER
    DEFAULT_ROLE = SVC_PIPELINE
    DEFAULT_WAREHOUSE = TRANSFORM_WH
    MUST_CHANGE_PASSWORD = FALSE
    COMMENT = 'GitHub Actions service user using key-pair authentication';

GRANT ROLE SVC_PIPELINE
TO USER SVC_PIPELINE_USER;