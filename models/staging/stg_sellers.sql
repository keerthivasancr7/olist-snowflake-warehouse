{{ config(materialized='view') }}

with ranked as (
    select
        *,
        row_number() over (
            partition by nullif(trim(seller_id), '')
            order by
                batch_seq desc,
                source_filename desc,
                source_row_number desc
        ) as row_rank
    from {{ source('olist_raw', 'sellers') }}
)

select
    nullif(trim(seller_id), '') as seller_id,
    nullif(trim(seller_zip_code_prefix), '') as seller_zip_code_prefix,
    lower(nullif(trim(seller_city), '')) as seller_city,
    upper(nullif(trim(seller_state), '')) as seller_state,
    ingested_at,
    source_filename,
    source_row_number,
    batch_id,
    batch_seq
from ranked
where row_rank = 1
