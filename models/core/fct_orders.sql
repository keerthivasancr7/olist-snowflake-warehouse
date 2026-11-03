{{ config(materialized='incremental', schema='CORE', incremental_strategy='merge', unique_key='order_id') }}

select
    order_id,
    customer_id,
    order_status,
    to_number(
        to_char(order_purchase_timestamp::date, 'YYYYMMDD')
    ) as purchase_date_key,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    order_status = 'delivered' as is_delivered,

    case
        when order_status = 'delivered'
             and order_delivered_customer_date is not null
             and order_estimated_delivery_date is not null
        then order_delivered_customer_date::date
             > order_estimated_delivery_date::date
        else null
    end as is_late,

    case
        when order_status = 'delivered'
             and order_delivered_customer_date is not null
        then datediff(
            'day',
            order_purchase_timestamp::date,
            order_delivered_customer_date::date
        )
        else null
    end as delivery_days,

    batch_id,
    batch_seq
from {{ ref('stg_orders') }} as src

{% if is_incremental() %}
where not exists (
    select 1
    from {{ this }} as existing
    where existing.order_id = src.order_id
          and existing.batch_seq >= src.batch_seq
)
{% endif %}
