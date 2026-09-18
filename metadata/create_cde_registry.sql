-- metadata/create_cde_registry.sql
-- Create and populate CDE (Critical Data Element) registry
-- Run as: snow sql -f metadata/create_cde_registry.sql

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- INSERT 25 CRITICAL DATA ELEMENTS
-- ============================================
INSERT INTO CDE_REGISTRY (CDE_ID, DATABASE_NAME, SCHEMA_NAME, TABLE_NAME, COLUMN_NAME, CDE_NAME, CRITICALITY_LEVEL, BUSINESS_OWNER, DESCRIPTION)
VALUES
(1, 'RAW', 'PUBLIC', 'CUSTOMER', 'CUSTOMER_ID', 'Customer Identifier', 'CRITICAL', 'Banking Operations', 'Unique identifier for all customers'),
(2, 'RAW', 'PUBLIC', 'CUSTOMER', 'TAX_ID', 'Tax Identifier', 'CRITICAL', 'Compliance', 'SSN/EIN required for tax reporting'),
(3, 'RAW', 'PUBLIC', 'CUSTOMER', 'DATE_OF_BIRTH', 'Customer Age', 'HIGH', 'Banking Operations', 'Age verification for products'),
(4, 'RAW', 'PUBLIC', 'ACCOUNT', 'ACCOUNT_ID', 'Account Identifier', 'CRITICAL', 'Deposits', 'Primary account reference'),
(5, 'RAW', 'PUBLIC', 'ACCOUNT', 'ACCOUNT_NUMBER', 'Account Number', 'CRITICAL', 'Deposits', 'Customer-facing account reference'),
(6, 'RAW', 'PUBLIC', 'ACCOUNT', 'BALANCE', 'Account Balance', 'CRITICAL', 'Deposits', 'Reconciles to GL controls'),
(7, 'RAW', 'PUBLIC', 'ACCOUNT', 'BRANCH_CODE', 'Branch Location', 'HIGH', 'Operations', 'Branch where account was opened'),
(8, 'RAW', 'PUBLIC', 'ACCOUNT', 'STATUS', 'Account Status', 'HIGH', 'Operations', 'Active/Inactive/Closed state'),
(9, 'RAW', 'PUBLIC', 'TRANSACTION', 'TRANSACTION_ID', 'Transaction Reference', 'CRITICAL', 'Deposits', 'Unique transaction identifier'),
(10, 'RAW', 'PUBLIC', 'TRANSACTION', 'AMOUNT', 'Transaction Amount', 'CRITICAL', 'Deposits', 'Dollar amount for reconciliation'),
(11, 'RAW', 'PUBLIC', 'TRANSACTION', 'BUSINESS_DATE', 'Transaction Date', 'HIGH', 'Deposits', 'Business date of transaction'),
(12, 'RAW', 'PUBLIC', 'TRANSACTION', 'ACCOUNT_ID', 'Related Account', 'CRITICAL', 'Deposits', 'Links transaction to account'),
(13, 'RAW', 'PUBLIC', 'LOAN', 'LOAN_ID', 'Loan Identifier', 'CRITICAL', 'Lending', 'Primary loan reference'),
(14, 'RAW', 'PUBLIC', 'LOAN', 'CUSTOMER_ID', 'Loan Customer', 'CRITICAL', 'Lending', 'Links loan to customer'),
(15, 'RAW', 'PUBLIC', 'LOAN', 'PRINCIPAL', 'Loan Principal Amount', 'CRITICAL', 'Lending', 'Original loan amount'),
(16, 'RAW', 'PUBLIC', 'LOAN', 'INTEREST_RATE', 'Loan Interest Rate', 'HIGH', 'Pricing', 'Annual percentage rate'),
(17, 'RAW', 'PUBLIC', 'LOAN', 'CREDIT_GRADE', 'Borrower Credit Grade', 'HIGH', 'Lending', 'Credit risk assessment'),
(18, 'RAW', 'PUBLIC', 'LOAN', 'COLLATERAL_VALUE', 'Collateral Value', 'HIGH', 'Lending', 'Asset value backing loan'),
(19, 'RAW', 'PUBLIC', 'LOAN', 'STATUS', 'Loan Status', 'HIGH', 'Lending', 'Active/Paid/Defaulted state'),
(20, 'RAW', 'PUBLIC', 'GL_CONTROL', 'GL_CODE', 'GL Account Code', 'CRITICAL', 'Finance', 'Reconciliation reference'),
(21, 'RAW', 'PUBLIC', 'GL_CONTROL', 'CONTROL_TOTAL', 'GL Control Total', 'CRITICAL', 'Finance', 'Reconciliation target amount'),
(22, 'RAW', 'PUBLIC', 'GL_CONTROL', 'RECORD_COUNT', 'GL Record Count', 'HIGH', 'Finance', 'Volume metric for reconciliation'),
(23, 'RAW', 'PUBLIC', 'BRANCH', 'BRANCH_CODE', 'Branch Identifier', 'HIGH', 'Operations', 'Physical branch location code'),
(24, 'RAW', 'PUBLIC', 'BRANCH', 'REGION', 'Geographic Region', 'MEDIUM', 'Operations', 'Region for branch classification'),
(25, 'RAW', 'PUBLIC', 'CUSTOMER', 'EMAIL', 'Customer Email', 'HIGH', 'Operations', 'Primary contact method');

-- Verify CDEs
SELECT COUNT(*) as total_cdes FROM CDE_REGISTRY;
SELECT CRITICALITY_LEVEL, COUNT(*) as count_by_level FROM CDE_REGISTRY GROUP BY CRITICALITY_LEVEL;

SELECT '✓ CDE Registry created and tags applied';
