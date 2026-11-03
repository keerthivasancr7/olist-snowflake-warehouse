{{ config(materialized='table', schema='MARTS') }}

select
    date_trunc(
        'month', o.order_purchase_timestamp
    )::date as purchase_month,
    count(distinct o.order_id) as delivered_orders,
    count(*) as delivered_items,
    sum(i.merchandise_value) as merchandise_value,
    sum(i.freight_value) as freight_value,
    sum(i.total_item_value) as total_item_value
from {{ ref('fct_orders') }} o
join {{ ref('fct_order_items') }} i
    on o.order_id = i.order_id
where o.is_delivered
group by 1
