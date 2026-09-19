-- tests/test_mart_deposits_timeliness.sql
-- TIMELINESS: Data must exist with a business date (not NULL)

select account_id, latest_business_date
from {{ ref('mart_deposits') }}
where latest_business_date is null