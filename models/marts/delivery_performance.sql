{{ config(materialized='table', schema='MARTS') }}

with monthly as (
    select
        date_trunc(
            'month', order_purchase_timestamp
        )::date as purchase_month,
        count(*) as delivered_orders,
        sum(case when is_late is not null then 1 else 0 end)
            as measurable_orders,
        sum(case when is_late then 1 else 0 end)
            as late_orders,
        sum(case when is_late is null then 1 else 0 end)
            as missing_delivery_dates,
        avg(delivery_days) as average_delivery_days
    from {{ ref('fct_orders') }}
    where is_delivered
    group by 1
)

select
    *,
    round(
        100.0 * late_orders / nullif(measurable_orders, 0),
        2
    ) as late_order_percentage
from monthly
