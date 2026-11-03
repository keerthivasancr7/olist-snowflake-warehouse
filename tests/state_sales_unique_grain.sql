select
    purchase_month,
    customer_state,
    count(*) as row_count
from {{ ref('state_sales') }}
group by purchase_month, customer_state
having count(*) > 1
    or purchase_month is null
    or customer_state is null
