{{ config(materialized='view') }}

with ranked as (
    select
        *,
        row_number() over (
            partition by nullif(trim(order_id), '')
            order by
                batch_seq desc,
                source_filename desc,
                source_row_number desc
        ) as row_rank
    from {{ source('olist_raw', 'orders') }}
)

select
    nullif(trim(order_id), '') as order_id,
    nullif(trim(customer_id), '') as customer_id,
    lower(nullif(trim(order_status), '')) as order_status,
    try_to_timestamp_ntz(
        nullif(trim(order_purchase_timestamp), '')
    ) as order_purchase_timestamp,
    try_to_timestamp_ntz(
        nullif(trim(order_approved_at), '')
    ) as order_approved_at,
    try_to_timestamp_ntz(
        nullif(trim(order_delivered_carrier_date), '')
    ) as order_delivered_carrier_date,
    try_to_timestamp_ntz(
        nullif(trim(order_delivered_customer_date), '')
    ) as order_delivered_customer_date,
    try_to_timestamp_ntz(
        nullif(trim(order_estimated_delivery_date), '')
    ) as order_estimated_delivery_date,
    ingested_at,
    source_filename,
    source_row_number,
    batch_id,
    batch_seq
from ranked
where row_rank = 1
