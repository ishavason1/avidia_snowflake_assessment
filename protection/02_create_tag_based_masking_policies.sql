-- protection/02_create_tag_based_masking_policies.sql
-- Update existing tag-based masking policies in place.
-- Policies are already attached, so ALTER ... SET BODY is used.

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================================
-- VARCHAR MASKING POLICY
-- DATA_OWNER and SVC_PIPELINE see clear values.
-- DATA_STEWARD sees partially masked values.
-- Other roles see fully masked values.
-- ============================================================

ALTER MASKING POLICY CLASSIFICATION_MASK_VARCHAR
SET BODY ->
  CASE
    WHEN SYSTEM$GET_TAG_ON_CURRENT_COLUMN(
           'GOVERNANCE.CATALOG.CLASSIFICATION'
         ) NOT IN ('PII', 'ACCOUNT_DETAILS', 'SENSITIVE')
      THEN VAL

    WHEN IS_ROLE_IN_SESSION('DATA_OWNER')
         OR IS_ROLE_IN_SESSION('SVC_PIPELINE')
      THEN VAL

    WHEN IS_ROLE_IN_SESSION('DATA_STEWARD')
      THEN
        CASE
          WHEN VAL IS NULL THEN NULL
          WHEN LENGTH(VAL) <= 4 THEN '****'
          ELSE LEFT(VAL, 2)
               || REPEAT('*', LENGTH(VAL) - 4)
               || RIGHT(VAL, 2)
        END

    ELSE '***MASKED***'
  END;


-- ============================================================
-- DATE MASKING POLICY
-- DATA_OWNER and SVC_PIPELINE see clear values.
-- DATA_STEWARD sees year-level partial value.
-- Other roles see NULL.
-- ============================================================

ALTER MASKING POLICY CLASSIFICATION_MASK_DATE
SET BODY ->
  CASE
    WHEN SYSTEM$GET_TAG_ON_CURRENT_COLUMN(
           'GOVERNANCE.CATALOG.CLASSIFICATION'
         ) NOT IN ('PII', 'ACCOUNT_DETAILS', 'SENSITIVE')
      THEN VAL

    WHEN IS_ROLE_IN_SESSION('DATA_OWNER')
         OR IS_ROLE_IN_SESSION('SVC_PIPELINE')
      THEN VAL

    WHEN IS_ROLE_IN_SESSION('DATA_STEWARD')
      THEN IFF(
        VAL IS NULL,
        NULL,
        DATE_FROM_PARTS(YEAR(VAL), 1, 1)
      )

    ELSE NULL
  END;


-- ============================================================
-- NUMBER MASKING POLICY
-- DATA_OWNER and SVC_PIPELINE see clear values.
-- DATA_STEWARD sees coarsened values.
-- Other roles see NULL.
-- ============================================================

ALTER MASKING POLICY CLASSIFICATION_MASK_NUMBER
SET BODY ->
  CASE
    WHEN SYSTEM$GET_TAG_ON_CURRENT_COLUMN(
           'GOVERNANCE.CATALOG.CLASSIFICATION'
         ) NOT IN ('PII', 'ACCOUNT_DETAILS', 'SENSITIVE')
      THEN VAL

    WHEN IS_ROLE_IN_SESSION('DATA_OWNER')
         OR IS_ROLE_IN_SESSION('SVC_PIPELINE')
      THEN VAL

    WHEN IS_ROLE_IN_SESSION('DATA_STEWARD')
      THEN FLOOR(VAL / 10000) * 10000

    ELSE NULL
  END;