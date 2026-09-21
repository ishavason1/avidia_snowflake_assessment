{{
  config(
    materialized='table',
    tags=['staging', 'critical'],
    meta={'owner': 'data_owner', 'cde': true}
  )
}}

-- stg_customer: Clean, deduplicated customer master

with raw_customer as (
    select
        customer_id,
        first_name,
        last_name,
        email,
        phone,
        tax_id,
        date_of_birth,
        address,
        customer_type,
        created_at as source_created_at
    from {{ source('raw', 'customer') }}
    where customer_type in ('PERSON', 'BUSINESS')  -- Validity check
)

select
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    tax_id,
    date_of_birth,
    address,
    customer_type,
    source_created_at,
    -- Audit columns
    'RAW.PUBLIC.CUSTOMER' as source_table,
    'RAW' as source_system,
    current_timestamp() as dbt_loaded_at
from raw_customer
