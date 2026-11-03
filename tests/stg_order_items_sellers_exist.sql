select i.*
from {{ ref('stg_order_items') }} i
where not exists (
    select 1
    from {{ ref('stg_sellers') }} s
    where s.seller_id = i.seller_id
)
