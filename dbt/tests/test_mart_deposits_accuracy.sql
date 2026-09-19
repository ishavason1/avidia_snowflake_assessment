-- tests/test_mart_deposits_accuracy.sql
-- ACCURACY: Mart total deposit balances must reconcile to GL within $1

with mart_totals as (
  select sum(current_balance) as mart_total_balance
  from {{ ref('mart_deposits') }}
),

gl_totals as (
  select sum(control_total) as gl_total_deposits
  from {{ source('raw', 'gl_control') }}
  where account_type = 'DEPOSITS'
)

select
  abs(mt.mart_total_balance - gt.gl_total_deposits) as reconciliation_difference
from mart_totals mt
cross join gl_totals gt
where abs(mt.mart_total_balance - gt.gl_total_deposits) > 1.00