select
    product_id,
    product_name,
    category,
    sub_category,
    brand,
    total_orders,
    total_quantity,
    total_sales
from {{ ref('int_product_sales') }}