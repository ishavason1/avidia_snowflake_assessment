-- classification/create_luhn_classifier.sql
-- Custom UDF for Card PAN validation using Luhn algorithm

USE ROLE DATA_OWNER;
USE DATABASE GOVERNANCE;
USE SCHEMA CATALOG;

-- ============================================
-- UDF: VALIDATE_LUHN (Card PAN validation)
-- ============================================
CREATE OR REPLACE FUNCTION VALIDATE_LUHN(card_number VARCHAR)
RETURNS BOOLEAN
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
HANDLER = 'validate_luhn'
AS
$$
def validate_luhn(card_number):
    """
    Validate card number using Luhn algorithm
    Used to detect real vs fake card numbers in free text
    """
    if card_number is None:
        return False
    
    # Remove non-digits
    number_str = ''.join(c for c in str(card_number) if c.isdigit())
    
    # Must be 13-19 digits (valid card range)
    if len(number_str) < 13 or len(number_str) > 19:
        return False
    
    # Luhn algorithm
    digits = [int(d) for d in number_str]
    checksum = 0
    
    # Process from right to left
    for i, digit in enumerate(reversed(digits)):
        # Double every second digit from right
        if i % 2 == 1:
            digit *= 2
            if digit > 9:
                digit -= 9
        checksum += digit
    
    # Valid if checksum % 10 == 0
    return checksum % 10 == 0
$$;

-- Test the UDF
SELECT 'Testing Luhn Validator:' as test;

-- Valid test card (Visa test number)
SELECT VALIDATE_LUHN('4532015112830366') as valid_visa;

-- Invalid number
SELECT VALIDATE_LUHN('1234567890123456') as invalid_card;

SELECT '✓ Luhn validator UDF created' as status;
