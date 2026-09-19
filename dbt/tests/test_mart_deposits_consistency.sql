-- tests/test_mart_deposits_consistency.sql
-- CONSISTENCY: Foreign key account.customer_id must reference valid customer (no orphans)

select
  md.account_id,
  md.customer_id
from {{ ref('mart_deposits') }} md
left join {{ ref('stg_customer') }} c on md.customer_id = c.customer_id
where c.customer_id is null