-- classification/05_load_sealed_sensitive_list.sql
-- Load the pre-sealed sensitive-column truth set used only for
-- classifier evaluation (precision / recall), not for auto-approval.
--
-- Note:
-- The original sealed list was found incomplete during validation because
-- FIRST_NAME, LAST_NAME, and ADDRESS were omitted even though they are PII.
-- These columns are included in the corrected evaluation baseline.

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

CREATE TABLE IF NOT EXISTS SEALED_SENSITIVE_COLUMNS (
    TABLE_NAME VARCHAR,
    COLUMN_NAME VARCHAR,
    EXPECTED_CLASSIFICATION VARCHAR,
    SOURCE_SECTION VARCHAR,
    REASON VARCHAR,
    PRIMARY KEY (TABLE_NAME, COLUMN_NAME)
);

TRUNCATE TABLE SEALED_SENSITIVE_COLUMNS;

INSERT INTO SEALED_SENSITIVE_COLUMNS (
    TABLE_NAME,
    COLUMN_NAME,
    EXPECTED_CLASSIFICATION,
    SOURCE_SECTION,
    REASON
)
VALUES

    -- CUSTOMER PII
    (
        'CUSTOMER',
        'FIRST_NAME',
        'PII',
        'CONFIRMED',
        'Direct personal identifier'
    ),
    (
        'CUSTOMER',
        'LAST_NAME',
        'PII',
        'CONFIRMED',
        'Direct personal identifier'
    ),
    (
        'CUSTOMER',
        'ADDRESS',
        'PII',
        'CONFIRMED',
        'Customer physical address'
    ),
    (
        'CUSTOMER',
        'TAX_ID',
        'PII',
        'CONFIRMED',
        'Regulated tax identifier'
    ),
    (
        'CUSTOMER',
        'DATE_OF_BIRTH',
        'PII',
        'CONFIRMED',
        'Identity and age information'
    ),
    (
        'CUSTOMER',
        'EMAIL',
        'PII',
        'CONFIRMED',
        'Contact identifier'
    ),
    (
        'CUSTOMER',
        'PHONE',
        'PII',
        'CONFIRMED',
        'Contact identifier'
    ),

    -- ACCOUNT
    (
        'ACCOUNT',
        'ACCOUNT_NUMBER',
        'ACCOUNT_DETAILS',
        'CONFIRMED',
        'Core banking account identifier'
    ),

    -- Deliberately mislabeled / contextual sensitive columns
    (
        'LOAN',
        'LOAN_MEMO',
        'POTENTIALLY_SENSITIVE',
        'MISLABELED',
        'Free text may contain payment card PAN'
    ),
    (
        'ACCOUNT',
        'BRANCH_CODE',
        'QUASI_IDENTIFIER',
        'MISLABELED',
        'Can contribute to re-identification'
    ),
    (
        'TRANSACTION',
        'MEMO',
        'POTENTIALLY_SENSITIVE',
        'MISLABELED',
        'Free text may contain sensitive context'
    ),
    (
        'LOAN',
        'COLLATERAL_VALUE',
        'SENSITIVE',
        'MISLABELED',
        'Asset value enables wealth inference'
    );

-- Evidence
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    EXPECTED_CLASSIFICATION,
    SOURCE_SECTION,
    REASON
FROM SEALED_SENSITIVE_COLUMNS
ORDER BY TABLE_NAME, COLUMN_NAME;

SELECT
    COUNT(*) AS SEALED_COLUMN_COUNT
FROM SEALED_SENSITIVE_COLUMNS;