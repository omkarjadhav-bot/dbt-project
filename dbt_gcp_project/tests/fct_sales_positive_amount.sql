select
    order_id,
    product_id,
    net_amount
from {{ ref('fct_sales') }}
where net_amount < 0