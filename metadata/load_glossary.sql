-- metadata/load_glossary.sql
-- Load banking glossary terms and map to columns
-- Run as: snow sql -f metadata/load_glossary.sql

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- INSERT GLOSSARY TERMS
-- ============================================
INSERT INTO BANKING_GLOSSARY (TERM_ID, TERM_NAME, DEFINITION, BUSINESS_DOMAIN, SYNONYMS)
VALUES
(1, 'Customer ID', 'Unique identifier for a customer in the banking system', 'CUSTOMER', 'CUST_ID, CUSTOMER_REF'),
(2, 'Tax ID', 'Government-issued tax identifier (SSN for individuals, EIN for businesses)', 'CUSTOMER', 'SSN, EIN, TIN'),
(3, 'Account Number', 'Unique identifier for a deposit account', 'DEPOSIT', 'ACCT_NUM, ACCOUNT_REF'),
(4, 'Balance', 'Current available balance in a deposit account', 'DEPOSIT', 'AVAILABLE_BALANCE, ACCOUNT_BALANCE'),
(5, 'Transaction', 'Any debit, credit, or transfer of funds', 'DEPOSIT', 'TXN, POSTING'),
(6, 'Branch Code', 'Unique identifier for a physical bank branch location', 'REFERENCE', 'BRANCH_ID, LOCATION_CODE'),
(7, 'GL Code', 'General Ledger account code for financial reconciliation', 'GL', 'GL_ACCOUNT, CONTROL_ACCOUNT'),
(8, 'Principal', 'The original amount borrowed in a loan', 'LOAN', 'LOAN_AMOUNT, ORIGINAL_BALANCE'),
(9, 'Credit Grade', 'Risk assessment rating of a borrower (A, B, C, D)', 'LOAN', 'CREDIT_RATING, RISK_RATING'),
(10, 'Collateral', 'Asset pledged as security for a loan', 'LOAN', 'SECURITY, PLEDGE');

-- ============================================
-- MAP GLOSSARY TERMS TO COLUMNS
-- ============================================
INSERT INTO GLOSSARY_TERM_MAPPINGS (DATABASE_NAME, SCHEMA_NAME, TABLE_NAME, COLUMN_NAME, TERM_ID)
VALUES
('RAW', 'PUBLIC', 'CUSTOMER', 'CUSTOMER_ID', 1),
('RAW', 'PUBLIC', 'CUSTOMER', 'TAX_ID', 2),
('RAW', 'PUBLIC', 'ACCOUNT', 'ACCOUNT_ID', 3),
('RAW', 'PUBLIC', 'ACCOUNT', 'ACCOUNT_NUMBER', 3),
('RAW', 'PUBLIC', 'ACCOUNT', 'BALANCE', 4),
('RAW', 'PUBLIC', 'TRANSACTION', 'TRANSACTION_ID', 5),
('RAW', 'PUBLIC', 'TRANSACTION', 'AMOUNT', 5),
('RAW', 'PUBLIC', 'BRANCH', 'BRANCH_CODE', 6),
('RAW', 'PUBLIC', 'GL_CONTROL', 'GL_CODE', 7),
('RAW', 'PUBLIC', 'LOAN', 'PRINCIPAL', 8),
('RAW', 'PUBLIC', 'LOAN', 'CREDIT_GRADE', 9),
('RAW', 'PUBLIC', 'LOAN', 'COLLATERAL_VALUE', 10);

-- Verify glossary
SELECT COUNT(*) as glossary_terms FROM BANKING_GLOSSARY;
SELECT COUNT(*) as term_mappings FROM GLOSSARY_TERM_MAPPINGS;

SELECT '✓ Banking glossary loaded';
