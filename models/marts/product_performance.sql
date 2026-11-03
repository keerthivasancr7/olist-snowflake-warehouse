{{ config(materialized='table', schema='MARTS') }}

select
    p.product_id,
    p.product_category_name,
    count(distinct o.order_id) as delivered_orders,
    count(*) as delivered_items,
    sum(i.merchandise_value) as merchandise_value,
    sum(i.freight_value) as freight_value,
    sum(i.total_item_value) as total_item_value
from {{ ref('fct_order_items') }} i
join {{ ref('fct_orders') }} o
    on i.order_id = o.order_id
join {{ ref('dim_products') }} p
    on i.product_id = p.product_id
where o.is_delivered
group by 1, 2
