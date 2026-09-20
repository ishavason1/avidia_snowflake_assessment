-- tests/test_mart_deposits_validity.sql
-- VALIDITY: validate the generated PERSON/BUSINESS tax-ID format.
-- Keep the raw tax ID out of stored failure evidence.
{{ config(
    tags=['quality', 'mart_deposits'],
    meta={
        'assessment': 'deposits',
        'check_dimension': 'VALIDITY',
        'target_column': 'TAX_ID,CUSTOMER_TYPE',
        'failure_unit': 'MART_ROW'
    }
) }}
select
  account_id,
  customer_type,
  case
    when customer_type is null then 'NULL_CUSTOMER_TYPE'
    when customer_type not in ('PERSON', 'BUSINESS') then 'UNSUPPORTED_CUSTOMER_TYPE'
    when tax_id is null then 'NULL_TAX_ID'
    else 'INVALID_TAX_ID_FORMAT'
  end as failure_reason
from {{ ref('mart_deposits') }}
where customer_type is null
   or customer_type not in ('PERSON', 'BUSINESS')
   or tax_id is null
   or (customer_type = 'PERSON' and not regexp_like(tax_id, '^[0-9]{3}-[0-9]{2}-[0-9]{4}$'))
   or (customer_type = 'BUSINESS' and not regexp_like(tax_id, '^[0-9]{2}-[0-9]{7}$'))
