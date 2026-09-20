-- tests/test_mart_deposits_accuracy.sql
-- ACCURACY: one current GL snapshot, reconciled by eligible account type.
-- Failure unit: one batch-snapshot issue or one failing account-type comparison.

{{ config(
    tags=['quality', 'mart_deposits'],
    meta={
        'assessment': 'deposits',
        'check_dimension': 'ACCURACY',
        'target_column': 'CURRENT_BALANCE,ACCOUNT_TYPE',
        'failure_unit': 'RECONCILIATION_ISSUE'
    }
) }}
with expected_types as (
  select account_type
  from {{ ref('stg_account') }}
  where status = 'ACTIVE' and account_type in ('CHECKING', 'SAVINGS')
  group by account_type
), mart_totals as (
  select account_type, count(*) as mart_rows,
         count(current_balance) as non_null_balances,
         sum(current_balance) as mart_total_balance
  from {{ ref('mart_deposits') }}
  group by account_type
), gl_snapshot as (
  select count(*) as gl_rows, count(as_of_date) as dated_rows,
         min(as_of_date) as first_date, max(as_of_date) as last_date
  from {{ source('raw', 'gl_control') }}
), gl_totals as (
  select account_type, count(*) as control_rows,
         count(gl_code) as non_null_codes,
         count(control_total) as non_null_totals,
         count(record_count) as non_null_counts,
         count(as_of_date) as non_null_dates,
         min(as_of_date) as control_date,
         min(control_total) as control_total,
         min(record_count) as record_count
  from {{ source('raw', 'gl_control') }}
  group by account_type
), account_types as (
  select account_type from expected_types
  union
  select account_type from mart_totals
  union
  select account_type from gl_totals
), comparisons as (
  select k.account_type, e.account_type as expected_type,
         s.first_date as snapshot_date,
         m.mart_rows, m.non_null_balances, m.mart_total_balance,
         g.control_rows, g.non_null_codes, g.non_null_totals,
         g.non_null_counts, g.non_null_dates, g.control_date,
         g.control_total, g.record_count,
         abs(m.mart_total_balance - g.control_total) as reconciliation_difference
  from account_types k
  left join expected_types e on k.account_type = e.account_type
  left join mart_totals m on k.account_type = m.account_type
  left join gl_totals g on k.account_type = g.account_type
  cross join gl_snapshot s
)
select
  'INVALID_GL_SNAPSHOT' as failure_reason,
  cast(null as varchar) as account_type,
  cast(null as date) as snapshot_date,
  gl_rows as control_rows,
  cast(null as number) as mart_rows,
  cast(null as number) as record_count,
  cast(null as number(38, 2)) as mart_total_balance,
  cast(null as number(38, 2)) as control_total,
  cast(null as number(38, 2)) as reconciliation_difference
from gl_snapshot
where gl_rows = 0 or dated_rows <> gl_rows or first_date <> last_date

union all

select
  'ACCOUNT_TYPE_RECONCILIATION' as failure_reason,
  account_type, snapshot_date, control_rows, mart_rows, record_count,
  mart_total_balance, control_total, reconciliation_difference
from comparisons
where account_type is null or expected_type is null
   or mart_rows is null or control_rows is null
   or control_rows <> 1
   or non_null_codes <> control_rows
   or non_null_totals <> control_rows
   or non_null_counts <> control_rows
   or non_null_dates <> control_rows
   or control_date <> snapshot_date
   or non_null_balances <> mart_rows
   or mart_total_balance is null
   or record_count <> mart_rows
   or reconciliation_difference > 1.00
