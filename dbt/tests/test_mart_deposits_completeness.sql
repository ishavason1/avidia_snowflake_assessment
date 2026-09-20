-- tests/test_mart_deposits_completeness.sql
-- COMPLETENESS: Critical data element (account_id) must NOT be NULL
{{ config(
    tags=['quality', 'mart_deposits'],
    meta={
        'assessment': 'deposits',
        'check_dimension': 'COMPLETENESS',
        'target_column': 'ACCOUNT_ID',
        'failure_unit': 'MART_ROW'
    }
) }}
select
  account_id,
  customer_id,
  account_type
from {{ ref('mart_deposits') }}
where account_id is null
