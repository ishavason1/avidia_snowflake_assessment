{{
  config(
    materialized='table',
    database='analytics',
    schema='staging',
    tags=['staging', 'critical'],
    meta={'owner': 'data_owner', 'cde': false}
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
  current_timestamp() as dbt_loaded_at,
  'RAW.PUBLIC.CUSTOMER' as source_table,
  'RAW' as source_system
from raw_customer