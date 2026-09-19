-- tests/test_mart_deposits_validity.sql
-- VALIDITY: status must be in valid domain (ACTIVE, CLOSED, INACTIVE)

select
  account_id,
  status
from {{ ref('mart_deposits') }}
where status not in ('ACTIVE', 'CLOSED', 'INACTIVE')