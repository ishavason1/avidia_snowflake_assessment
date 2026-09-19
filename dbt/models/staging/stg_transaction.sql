{{
  config(
    materialized='table',
    database='analytics',
    schema='staging',
    tags=['staging'],
    meta={'owner': 'data_owner', 'cde': false}
  )
}}

-- stg_transaction: Clean, standardized transactions

with raw_transaction as (
  select
    transaction_id,
    account_id,
    business_date,
    transaction_type,
    amount,
    memo,
    created_at as source_created_at
  from {{ source('raw', 'transaction') }}
  where amount > 0  -- Validity: transaction must have positive amount
    and transaction_type in ('DEBIT', 'CREDIT')
)

select
  transaction_id,
  account_id,
  business_date,
  transaction_type,
  amount,
  memo,
  source_created_at,
  -- Audit columns
  current_timestamp() as dbt_loaded_at,
  'RAW.PUBLIC.TRANSACTION' as source_table,
  'RAW' as source_system
from raw_transaction