-- tests/test_mart_deposits_completeness.sql
-- COMPLETENESS: Critical data element (account_id) must NOT be NULL

select
  count(*) as failed_rows
from {{ ref('mart_deposits') }}
where account_id is null

having count(*) > 0
