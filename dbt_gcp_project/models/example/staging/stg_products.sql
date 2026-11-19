select
    product_id,
    product_name,
    category,
    sub_category,
    brand
from {{ source('raw', 'raw_products') }}