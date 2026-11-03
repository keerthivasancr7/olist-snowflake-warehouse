with expected as (
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
),

actual as (
    select *
    from {{ ref('monthly_delivered_sales') }}
)

select
    coalesce(e.purchase_month, a.purchase_month) as purchase_month
from expected e
full outer join actual a
    on e.purchase_month = a.purchase_month
where e.purchase_month is null
   or a.purchase_month is null
   or e.delivered_orders is distinct from a.delivered_orders
   or e.delivered_items is distinct from a.delivered_items
   or e.merchandise_value is distinct from a.merchandise_value
   or e.freight_value is distinct from a.freight_value
   or e.total_item_value is distinct from a.total_item_value
   or a.total_item_value is distinct from
      (a.merchandise_value + a.freight_value)
