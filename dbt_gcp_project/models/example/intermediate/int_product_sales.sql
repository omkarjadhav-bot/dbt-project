select
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    p.brand,

    count(distinct oi.order_id) as total_orders,

    sum(oi.quantity) as total_quantity,

    sum(
        (oi.quantity * oi.unit_price) - oi.discount
    ) as total_sales

from {{ ref('stg_order_items') }} oi

inner join {{ ref('stg_products') }} p
    on oi.product_id = p.product_id

group by
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    p.brand