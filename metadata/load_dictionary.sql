-- metadata/load_dictionary.sql
-- Load data dictionary (idempotent with MERGE)
-- Descriptions are stored in GOVERNANCE.CATALOG.DATA_DICTIONARY table

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- LOAD DICTIONARY (Idempotent - MERGE)
-- ============================================

MERGE INTO DATA_DICTIONARY dd
USING (
  SELECT * FROM (
    VALUES
    ('CUSTOMER', 'CUSTOMER_ID', 'Unique customer identifier', 'VARCHAR', 'PUBLIC', TRUE, 'Primary key'),
    ('CUSTOMER', 'FIRST_NAME', 'Customer first name', 'VARCHAR', 'PUBLIC', FALSE, 'For persons only'),
    ('CUSTOMER', 'LAST_NAME', 'Customer last name', 'VARCHAR', 'PUBLIC', FALSE, 'For persons only'),
    ('CUSTOMER', 'CUSTOMER_TYPE', 'PERSON or BUSINESS', 'VARCHAR', 'PUBLIC', FALSE, 'Business logic flag'),
    ('CUSTOMER', 'TAX_ID', 'Tax ID (SSN or EIN)', 'VARCHAR', 'PII', TRUE, 'Will be masked for analysts'),
    ('CUSTOMER', 'DATE_OF_BIRTH', 'Date of birth', 'DATE', 'PII', FALSE, 'Age inference risk'),
    ('CUSTOMER', 'EMAIL', 'Email address', 'VARCHAR', 'PII', FALSE, 'Contact info'),
    ('CUSTOMER', 'PHONE', 'Phone number', 'VARCHAR', 'PII', FALSE, 'Contact info'),
    ('CUSTOMER', 'ADDRESS', 'Full mailing address', 'VARCHAR', 'PUBLIC', FALSE, 'Non-sensitive location'),
    ('CUSTOMER', 'CREATED_AT', 'Record created timestamp', 'TIMESTAMP_NTZ', 'PUBLIC', FALSE, 'Audit trail'),
    ('ACCOUNT', 'ACCOUNT_ID', 'Unique account identifier', 'VARCHAR', 'PUBLIC', TRUE, 'Primary key'),
    ('ACCOUNT', 'CUSTOMER_ID', 'Reference to customer', 'VARCHAR', 'PUBLIC', FALSE, 'Foreign key'),
    ('ACCOUNT', 'ACCOUNT_TYPE', 'CHECKING/SAVINGS/MONEY_MARKET', 'VARCHAR', 'PUBLIC', FALSE, 'Business logic'),
    ('ACCOUNT', 'ACCOUNT_NUMBER', '10-digit account number', 'VARCHAR', 'ACCOUNT_DETAILS', TRUE, 'Custom classifier detects'),
    ('ACCOUNT', 'BRANCH_CODE', 'Branch code (BR_XX)', 'VARCHAR', 'PUBLIC', FALSE, 'For row access policy'),
    ('ACCOUNT', 'BALANCE', 'Current account balance', 'DECIMAL', 'PUBLIC', TRUE, 'Reconciles to GL'),
    ('ACCOUNT', 'STATUS', 'ACTIVE/INACTIVE/CLOSED', 'VARCHAR', 'PUBLIC', FALSE, 'Lifecycle status'),
    ('ACCOUNT', 'OPENED_DATE', 'Date account opened', 'DATE', 'PUBLIC', FALSE, 'Audit trail'),
    ('TRANSACTION', 'TRANSACTION_ID', 'Unique transaction identifier', 'VARCHAR', 'PUBLIC', TRUE, 'Primary key'),
    ('TRANSACTION', 'ACCOUNT_ID', 'Reference to account', 'VARCHAR', 'PUBLIC', FALSE, 'Foreign key'),
    ('TRANSACTION', 'TRANSACTION_TYPE', 'DEPOSIT/WITHDRAWAL/TRANSFER', 'VARCHAR', 'PUBLIC', FALSE, 'Business logic'),
    ('TRANSACTION', 'AMOUNT', 'Transaction amount in USD', 'DECIMAL', 'PUBLIC', TRUE, 'For reconciliation'),
    ('TRANSACTION', 'BUSINESS_DATE', 'Date transaction occurred', 'DATE', 'PUBLIC', FALSE, 'For time-series'),
    ('TRANSACTION', 'MEMO', 'Transaction description', 'VARCHAR', 'POTENTIALLY_SENSITIVE', FALSE, 'May contain hidden PII'),
    ('LOAN', 'LOAN_ID', 'Unique loan identifier', 'VARCHAR', 'PUBLIC', TRUE, 'Primary key'),
    ('LOAN', 'CUSTOMER_ID', 'Reference to customer', 'VARCHAR', 'PUBLIC', FALSE, 'Foreign key'),
    ('LOAN', 'LOAN_TYPE', 'PERSONAL/HOME/AUTO/BUSINESS', 'VARCHAR', 'PUBLIC', FALSE, 'Business logic'),
    ('LOAN', 'PRINCIPAL', 'Loan principal amount', 'DECIMAL', 'PUBLIC', TRUE, 'Reconciliation'),
    ('LOAN', 'INTEREST_RATE', 'Annual interest rate', 'DECIMAL', 'PUBLIC', FALSE, 'Pricing'),
    ('LOAN', 'CREDIT_GRADE', 'Credit rating (A/B/C/D)', 'VARCHAR', 'PUBLIC', FALSE, 'Risk classification'),
    ('LOAN', 'COLLATERAL_VALUE', 'Value of collateral', 'DECIMAL', 'PUBLIC', FALSE, 'Risk mitigation'),
    ('LOAN', 'LOAN_MEMO', 'Loan approval notes', 'VARCHAR', 'POTENTIALLY_SENSITIVE', FALSE, 'May contain card PANs'),
    ('LOAN', 'STATUS', 'Loan status (ACTIVE/PAID/DEFAULTED)', 'VARCHAR', 'PUBLIC', FALSE, 'Lifecycle'),
    ('GL_CONTROL', 'GL_CODE', 'GL account code', 'VARCHAR', 'PUBLIC', FALSE, 'Reconciliation reference'),
    ('GL_CONTROL', 'CONTROL_TOTAL', 'Total balance for account type', 'DECIMAL', 'PUBLIC', TRUE, 'Reconciliation target'),
    ('GL_CONTROL', 'RECORD_COUNT', 'Number of records', 'INTEGER', 'PUBLIC', FALSE, 'Volume metric'),
    ('BRANCH', 'BRANCH_CODE', 'Branch identifier', 'VARCHAR', 'PUBLIC', FALSE, 'Physical location'),
    ('PRODUCT', 'PRODUCT_CODE', 'Product code', 'VARCHAR', 'PUBLIC', FALSE, 'Product reference')
  ) as t(TABLE_NAME, COLUMN_NAME, COLUMN_DESCRIPTION, DATA_TYPE, SENSITIVITY_CLASSIFICATION, IS_CDE, NOTES)
) s
ON dd.TABLE_NAME = s.TABLE_NAME AND dd.COLUMN_NAME = s.COLUMN_NAME
WHEN MATCHED THEN
  UPDATE SET 
    COLUMN_DESCRIPTION = s.COLUMN_DESCRIPTION,
    DATA_TYPE = s.DATA_TYPE,
    SENSITIVITY_CLASSIFICATION = s.SENSITIVITY_CLASSIFICATION,
    IS_CDE = s.IS_CDE,
    NOTES = s.NOTES,
    LOADED_AT = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
  INSERT (TABLE_NAME, COLUMN_NAME, COLUMN_DESCRIPTION, DATA_TYPE, SENSITIVITY_CLASSIFICATION, IS_CDE, NOTES, LOADED_AT)
  VALUES (s.TABLE_NAME, s.COLUMN_NAME, s.COLUMN_DESCRIPTION, s.DATA_TYPE, s.SENSITIVITY_CLASSIFICATION, s.IS_CDE, s.NOTES, CURRENT_TIMESTAMP());

-- Verify
SELECT 'Dictionary Loaded (Idempotent):' as status;
SELECT COUNT(*) as total_rows FROM DATA_DICTIONARY;

SELECT 'Sample Dictionary Entries:' as status;
SELECT TABLE_NAME, COLUMN_NAME, SENSITIVITY_CLASSIFICATION, IS_CDE 
FROM DATA_DICTIONARY 
ORDER BY TABLE_NAME, COLUMN_NAME 
LIMIT 10;
