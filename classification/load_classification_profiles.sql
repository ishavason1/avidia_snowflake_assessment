-- classification/load_classification_profiles.sql
-- Load pattern-based classification profiles

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- INSERT CLASSIFICATION PROFILES
-- ============================================
INSERT INTO CLASSIFICATION_PROFILES (PROFILE_ID, PROFILE_NAME, PATTERN_RULE, CLASSIFICATION, SENSITIVITY_LEVEL, DETECTION_METHOD)
VALUES
(1, 'SSN Pattern', '^\d{3}-\d{2}-\d{4}$', 'PII', 'CRITICAL', 'REGEX_MATCH'),
(2, 'Email Pattern', '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', 'PII', 'HIGH', 'REGEX_MATCH'),
(3, 'Phone Pattern', '^\d{3}-\d{3}-\d{4}$', 'PII', 'HIGH', 'REGEX_MATCH'),
(4, 'Account Number Pattern', '^\d{10}$', 'ACCOUNT_DETAILS', 'CRITICAL', 'FORMAT_MATCH'),
(5, 'Date of Birth Pattern', '^\d{4}-\d{2}-\d{2}$', 'PII', 'HIGH', 'FORMAT_MATCH'),
(6, 'Credit Card PAN', '^[0-9]{13,19}$', 'ACCOUNT_DETAILS', 'CRITICAL', 'LUHN_VALIDATION'),
(7, 'Column Name: password', 'PASSWORD|PASSWD|PWD', 'SENSITIVE', 'CRITICAL', 'NAME_MATCH'),
(8, 'Column Name: secret', 'SECRET|PRIVATE_KEY|API_KEY', 'SENSITIVE', 'CRITICAL', 'NAME_MATCH'),
(9, 'Column Name: email', 'EMAIL|E_MAIL|EMAIL_ADDRESS', 'PII', 'HIGH', 'NAME_MATCH'),
(10, 'Column Name: phone', 'PHONE|TELEPHONE|MOBILE|CELL', 'PII', 'HIGH', 'NAME_MATCH');

SELECT 'Classification profiles loaded:' as status;
SELECT COUNT(*) as profile_count FROM CLASSIFICATION_PROFILES;

SELECT '✓ Classification profiles loaded' as status;
