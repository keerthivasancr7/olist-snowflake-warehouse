select purchase_month
from {{ ref('delivery_performance') }}
where purchase_month is null
   or delivered_orders is null
   or measurable_orders is null
   or late_orders is null
   or missing_delivery_dates is null
   or measurable_orders + missing_delivery_dates <> delivered_orders
   or late_orders < 0
   or late_orders > measurable_orders
   or (
       measurable_orders > 0
       and (
           late_order_percentage is null
           or late_order_percentage <> round(
               100.0 * late_orders / measurable_orders, 2
           )
       )
   )
   or (
       measurable_orders = 0
       and late_order_percentage is not null
   )

union all

select purchase_month
from {{ ref('delivery_performance') }}
group by purchase_month
having count(*) > 1
