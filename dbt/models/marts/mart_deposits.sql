{{
  config(
    materialized='table',
    tags=['staging', 'critical'],
    meta={'owner': 'data_owner', 'cde': true}
  )
}}

-- Current snapshot: one row per ACTIVE CHECKING/SAVINGS account (ACCOUNT_ID).
-- GL reconciliation is separate, by account type and source snapshot date.

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
    -- Latest valid transaction date; NULL when no dated staged transaction exists.
    txn.latest_business_date,
    'ANALYTICS.MARTS.MART_DEPOSITS' as mart_name,
    coalesce(txn.transaction_count, 0) as transaction_count,
    coalesce(txn.total_debits, 0) as total_debits,

    -- Audit
    coalesce(txn.total_credits, 0) as total_credits,
    current_timestamp() as dbt_refreshed_at,
    current_date() as dbt_business_date

from accounts as a
left join customers as c on a.customer_id = c.customer_id
left join account_transactions as txn on a.account_id = txn.account_id

where a.status = 'ACTIVE'  -- Only active deposit accounts
