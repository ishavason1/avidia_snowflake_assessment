{{
  config(
    materialized='table',
    tags=['staging', 'critical'],
    meta={'owner': 'data_owner', 'cde': true}
  )
}}
-- stg_account: Clean, standardized accounts

with raw_account as (
    select
        account_id,
        customer_id,
        account_number,
        account_type,
        status,
        balance,
        branch_code,
        opened_date,
        created_at as source_created_at
    from {{ source('raw', 'account') }}
    where status in ('ACTIVE', 'CLOSED')  -- Validity: must be valid status
)

select
    account_id,
    customer_id,
    account_number,
    account_type,
    status,
    balance,
    branch_code,
    opened_date,
    source_created_at,
    -- Audit columns
    'RAW.PUBLIC.ACCOUNT' as source_table,
    'RAW' as source_system,
    current_timestamp() as dbt_loaded_at
from raw_account
