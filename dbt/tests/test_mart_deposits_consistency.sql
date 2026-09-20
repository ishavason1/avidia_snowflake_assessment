-- tests/test_mart_deposits_consistency.sql
-- CONSISTENCY: Foreign key account.customer_id must reference valid customer (no orphans)

{{ config(
    tags=['quality', 'mart_deposits'],
    meta={
        'assessment': 'deposits',
        'check_dimension': 'CONSISTENCY',
        'target_column': 'CUSTOMER_ID',
        'failure_unit': 'MART_ROW'
    }
) }}
select
  md.account_id,
  md.customer_id
from {{ ref('mart_deposits') }} md
left join {{ ref('stg_customer') }} c on md.customer_id = c.customer_id
where c.customer_id is null