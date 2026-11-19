select
    order_id,
    product_id,
    quantity,
    unit_price,
    discount
from {{ source('raw', 'raw_order_items') }}