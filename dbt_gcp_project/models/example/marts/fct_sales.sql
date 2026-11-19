select
    o.order_id,
    o.order_date,
    o.order_status,
    o.payment_method,

    c.customer_id,
    c.customer_name,
    c.city,
    c.state,

    oi.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    p.brand,

    oi.quantity,
    oi.unit_price,
    oi.discount,

    oi.quantity * oi.unit_price as gross_amount,

    (oi.quantity * oi.unit_price) - oi.discount as net_amount

from {{ ref('stg_orders') }} o

inner join {{ ref('stg_order_items') }} oi
    on o.order_id = oi.order_id

inner join {{ ref('stg_customers') }} c
    on o.customer_id = c.customer_id

inner join {{ ref('stg_products') }} p
    on oi.product_id = p.product_id