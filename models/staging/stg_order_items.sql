{{ config(materialized='view') }}

with typed as (
    select
        nullif(trim(order_id), '') as order_id,
        try_to_decimal(
            nullif(trim(order_item_id), ''), 18, 0
        ) as order_item_id,
        nullif(trim(product_id), '') as product_id,
        nullif(trim(seller_id), '') as seller_id,
        try_to_timestamp_ntz(
            nullif(trim(shipping_limit_date), '')
        ) as shipping_limit_date,
        try_to_decimal(
            nullif(trim(price), ''), 18, 2
        ) as merchandise_value,
        try_to_decimal(
            nullif(trim(freight_value), ''), 18, 2
        ) as freight_value,
        ingested_at,
        source_filename,
        source_row_number,
        batch_id,
        batch_seq
    from {{ source('olist_raw', 'order_items') }}
),

ranked as (
    select
        *,
        row_number() over (
            partition by order_id, order_item_id
            order by
                batch_seq desc,
                source_filename desc,
                source_row_number desc
        ) as row_rank
    from typed
)

select
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    merchandise_value,
    freight_value,
    merchandise_value + freight_value as total_item_value,
    ingested_at,
    source_filename,
    source_row_number,
    batch_id,
    batch_seq
from ranked
where row_rank = 1
