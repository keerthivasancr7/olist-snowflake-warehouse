select i.*
from {{ ref('stg_order_items') }} i
where not exists (
    select 1
    from {{ ref('stg_products') }} p
    where p.product_id = i.product_id
)
