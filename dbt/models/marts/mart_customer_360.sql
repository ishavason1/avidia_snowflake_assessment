{{
  config(
    materialized='table',
    tags=['staging', 'critical'],
    meta={'owner': 'data_owner', 'cde': true}
  )
}}

-- mart_customer_360: 360-degree customer view with accounts, transactions, and loans

with customers as (
    select * from {{ ref('stg_customer') }}
),

customer_accounts as (
    select
        customer_id,
        count(*) as account_count,
        sum(case when account_type = 'SAVINGS' then 1 else 0 end) as savings_count,
        sum(case when account_type = 'CHECKING' then 1 else 0 end) as checking_count,
        sum(balance) as total_balance,
        max(opened_date) as most_recent_account_opened
    from {{ ref('stg_account') }}
    group by customer_id
),

customer_transactions as (
    select
        a.customer_id,
        count(t.transaction_id) as total_transactions,
        max(t.business_date) as latest_business_date,
        sum(case when t.transaction_type = 'DEBIT' then t.amount else 0 end) as total_debits,
        sum(case when t.transaction_type = 'CREDIT' then t.amount else 0 end) as total_credits
    from {{ ref('stg_account') }} as a
    left join {{ ref('stg_transaction') }} as t on a.account_id = t.account_id
    group by a.customer_id
),

customer_loans as (
    select
        customer_id,
        count(*) as loan_count,
        sum(case when status = 'ACTIVE' then 1 else 0 end) as active_loans,
        sum(case when status = 'PAID_OFF' then 1 else 0 end) as paid_off_loans,
        sum(case when status = 'DEFAULTED' then 1 else 0 end) as defaulted_loans,
        sum(principal) as total_loan_amount,
        avg(interest_rate) as avg_interest_rate,
        sum(collateral_value) as total_collateral_value,
        max(origination_date) as most_recent_loan_date
    from {{ ref('stg_loan') }}
    group by customer_id
)

select
    -- Customer basics
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.tax_id,
    c.date_of_birth,
    c.customer_type,
    c.address,

    -- Account portfolio
    ca.most_recent_account_opened,
    ct.latest_business_date,
    cl.avg_interest_rate,
    cl.most_recent_loan_date,
    coalesce(ca.account_count, 0) as account_count,

    -- Transaction activity
    coalesce(ca.savings_count, 0) as savings_count,
    coalesce(ca.checking_count, 0) as checking_count,
    coalesce(ca.total_balance, 0) as total_balance,
    coalesce(ct.total_transactions, 0) as total_transactions,

    -- Loan portfolio
    coalesce(ct.total_debits, 0) as total_debits,
    coalesce(ct.total_credits, 0) as total_credits,
    coalesce(cl.loan_count, 0) as loan_count,
    coalesce(cl.active_loans, 0) as active_loans,
    coalesce(cl.paid_off_loans, 0) as paid_off_loans,
    coalesce(cl.defaulted_loans, 0) as defaulted_loans,
    coalesce(cl.total_loan_amount, 0) as total_loan_amount,
    coalesce(cl.total_collateral_value, 0) as total_collateral_value,

    -- Audit
    current_timestamp() as dbt_refreshed_at,
    current_date() as dbt_business_date

from customers as c
left join customer_accounts as ca on c.customer_id = ca.customer_id
left join customer_transactions as ct on c.customer_id = ct.customer_id
left join customer_loans as cl on c.customer_id = cl.customer_id
