{{
  config(
    materialized='table',
    database='analytics',
    schema='staging',
    tags=['staging', 'critical'],
    meta={'owner': 'data_owner', 'cde': true}
  )
}}

with raw_loan as (
  select
    loan_id,
    customer_id,
    account_id,
    principal,
    loan_type,
    status,
    interest_rate,
    origination_date,
    collateral_value,
    credit_grade,
    loan_memo
  from {{ source('raw', 'loan') }}
  where principal > 0
    and credit_grade in ('A', 'B', 'C', 'D')
    and status in ('ACTIVE', 'DEFAULTED', 'PAID_OFF')
)

select
  loan_id,
  customer_id,
  account_id,
  principal,
  loan_type,
  status,
  interest_rate,
  origination_date,
  collateral_value,
  credit_grade,
  loan_memo,
  current_timestamp() as dbt_loaded_at,
  'RAW.PUBLIC.LOAN' as source_table,
  'RAW' as source_system
from raw_loan