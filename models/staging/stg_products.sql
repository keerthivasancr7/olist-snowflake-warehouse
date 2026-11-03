{{ config(materialized='view') }}

with ranked as (
    select
        *,
        row_number() over (
            partition by nullif(trim(product_id), '')
            order by
                batch_seq desc,
                source_filename desc,
                source_row_number desc
        ) as row_rank
    from {{ source('olist_raw', 'products') }}
)

select
    nullif(trim(product_id), '') as product_id,
    coalesce(
        lower(nullif(trim(product_category_name), '')),
        'unknown'
    ) as product_category_name,
    try_to_number(
        nullif(trim(product_name_lenght), '')
    ) as product_name_length,
    try_to_number(
        nullif(trim(product_description_lenght), '')
    ) as product_description_length,
    try_to_number(
        nullif(trim(product_photos_qty), '')
    ) as product_photos_qty,
    try_to_number(
        nullif(trim(product_weight_g), '')
    ) as product_weight_g,
    try_to_number(
        nullif(trim(product_length_cm), '')
    ) as product_length_cm,
    try_to_number(
        nullif(trim(product_height_cm), '')
    ) as product_height_cm,
    try_to_number(
        nullif(trim(product_width_cm), '')
    ) as product_width_cm,
    ingested_at,
    source_filename,
    source_row_number,
    batch_id,
    batch_seq
from ranked
where row_rank = 1
