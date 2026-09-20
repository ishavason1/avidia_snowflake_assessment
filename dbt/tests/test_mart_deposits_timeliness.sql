-- tests/test_mart_deposits_timeliness.sql
-- TIMELINESS: compare dataset watermarks for the same eligible population.

{{ config(
    tags=['quality', 'mart_deposits'],
    meta={
        'assessment': 'deposits',
        'check_dimension': 'TIMELINESS',
        'target_column': 'LATEST_BUSINESS_DATE',
        'failure_unit': 'DATASET_COMPARISON'
    }
) }}
with mart_watermark as (
  select count(*) as mart_rows, max(latest_business_date) as mart_latest_business_date
  from {{ ref('mart_deposits') }}
), source_watermark as (
  select max(t.business_date) as source_latest_business_date
  from {{ ref('stg_transaction') }} t
  join {{ ref('stg_account') }} a on t.account_id = a.account_id
  where a.status = 'ACTIVE'
    and a.account_type in ('CHECKING', 'SAVINGS')
)
select
  m.mart_rows,
  m.mart_latest_business_date,
  s.source_latest_business_date
from mart_watermark m
cross join source_watermark s
where m.mart_rows = 0
   or s.source_latest_business_date is null
   or m.mart_latest_business_date is null
   or m.mart_latest_business_date <> s.source_latest_business_date
