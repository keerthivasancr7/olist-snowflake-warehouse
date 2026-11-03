{{ config(materialized='view') }}

with source_data as (
    select *
    from {{ source('olist_raw', 'customers') }}
),

ranked as (
    select
        *,
        row_number() over (
            partition by nullif(trim(customer_id), '')
            order by
                batch_seq desc,
                source_filename desc,
                source_row_number desc
        ) as row_rank
    from source_data
)

select
    nullif(trim(customer_id), '') as customer_id,
    nullif(trim(customer_unique_id), '') as customer_unique_id,
    nullif(trim(customer_zip_code_prefix), '') as customer_zip_code_prefix,
    lower(nullif(trim(customer_city), '')) as customer_city,
    upper(nullif(trim(customer_state), '')) as customer_state,
    ingested_at,
    source_filename,
    source_row_number,
    batch_id,
    batch_seq
from ranked
where row_rank = 1
