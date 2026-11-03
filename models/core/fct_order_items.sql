{{ config(materialized='incremental', schema='CORE', incremental_strategy='merge', unique_key=['order_id', 'order_item_id']) }}

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    merchandise_value,
    freight_value,
    total_item_value,
    batch_id,
    batch_seq
from {{ ref('stg_order_items') }} as src

{% if is_incremental() %}
where not exists (
    select 1
    from {{ this }} as existing
    where existing.order_id = src.order_id
          and existing.order_item_id = src.order_item_id
          and existing.batch_seq >= src.batch_seq
)
{% endif %}
