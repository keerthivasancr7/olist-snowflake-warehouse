{{ config(materialized='table', schema='MARTS') }}

select
    c.customer_unique_id,
    count(*) as delivered_orders,
    min(o.order_purchase_timestamp)::date as first_purchase_date,
    max(o.order_purchase_timestamp)::date as latest_purchase_date,
    count(*) >= 2 as is_repeat_customer
from {{ ref('fct_orders') }} o
join {{ ref('dim_customers') }} c
    on o.customer_id = c.customer_id
where o.is_delivered
group by c.customer_unique_id
