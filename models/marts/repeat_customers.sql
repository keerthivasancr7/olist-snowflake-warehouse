{{ config(materialized='table', schema='MARTS') }}

select
    count(*) as purchasing_customers,
    coalesce(
        sum(case when is_repeat_customer then 1 else 0 end),
        0
    ) as repeat_customers,
    round(
        100.0 * repeat_customers / nullif(count(*), 0),
        2
    ) as repeat_customer_percentage
from {{ ref('customer_purchase_summary') }}
