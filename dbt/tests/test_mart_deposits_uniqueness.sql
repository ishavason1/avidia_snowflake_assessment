-- tests/test_mart_deposits_uniqueness.sql
-- UNIQUENESS: Business key (account_id) must be unique (no duplicates)

select
  account_id,
  count(*) as occurrence_count
from {{ ref('mart_deposits') }}
group by account_id
having count(*) > 1
