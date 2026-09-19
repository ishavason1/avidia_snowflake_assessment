{{
  config(
    materialized='table',
    database='analytics',
    schema='marts',
    tags=['marts', 'certified', 'critical'],
    meta={'owner': 'data_owner', 'steward': 'data_steward', 'certified': true, 'cde': true}
  )
}}

-- mart_deposits: Certified deposit accounts with customer context and GL reconciliation
-- 6 Quality Checks:
--   1. COMPLETENESS: account_id NOT NULL
--   2. UNIQUENESS: account_id unique
--   3. VALIDITY: status in valid values
--   4. CONSISTENCY: customer_id references customer
--   5. TIMELINESS: latest business_date is current
--   6. ACCURACY: SUM(balance) = GL_CONTROL.deposit_total ±$1

with accounts as (
  select * from {{ ref('stg_account') }}
  where account_type in ('SAVINGS', 'CHECKING')
),

customers as (
  select * from {{ ref('stg_customer') }}
),

account_transactions as (
  select
    account_id,
    max(business_date) as latest_business_date,
    count(*) as transaction_count,
    sum(case when transaction_type = 'DEBIT' then amount else 0 end) as total_debits,
    sum(case when transaction_type = 'CREDIT' then amount else 0 end) as total_credits
  from {{ ref('stg_transaction') }}
  group by account_id
),

gl_deposits as (
  select
    control_total as gl_total_deposits,
    as_of_date as gl_business_date
  from {{ source('raw', 'gl_control') }}
  where account_type = 'DEPOSITS'  -- Changed from GL_ACCOUNT
    and as_of_date = current_date()
)

select
  -- Account identifiers
  a.account_id,
  a.customer_id,
  a.account_number,

  -- Account details
  a.account_type,
  a.status,
  a.branch_code,
  a.opened_date,

  -- Balance information
  a.balance as current_balance,

  -- Customer context
  c.first_name,
  c.last_name,
  c.email,
  c.customer_type,
  c.tax_id,

  -- Transaction activity
  coalesce(at.latest_business_date, a.opened_date) as latest_business_date,
  coalesce(at.transaction_count, 0) as transaction_count,
  coalesce(at.total_debits, 0) as total_debits,
  coalesce(at.total_credits, 0) as total_credits,

  -- GL reconciliation context
  gl.gl_total_deposits,
  gl.gl_business_date,

  -- Audit
  current_timestamp() as dbt_refreshed_at,
  current_date() as dbt_business_date,
  'ANALYTICS.MARTS.MART_DEPOSITS' as mart_name

from accounts a
left join customers c on a.customer_id = c.customer_id
left join account_transactions at on a.account_id = at.account_id
cross join gl_deposits gl

where a.status = 'ACTIVE'  -- Only active deposit accounts