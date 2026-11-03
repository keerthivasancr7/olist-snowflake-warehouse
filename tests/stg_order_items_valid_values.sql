select *
from {{ ref('stg_order_items') }}
where order_item_id < 1
   or merchandise_value < 0
   or freight_value < 0
   or total_item_value is null
   or total_item_value <> merchandise_value + freight_value
