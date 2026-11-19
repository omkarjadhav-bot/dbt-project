select
    c.customer_id,
    c.customer_name,
    c.city,
    c.state,
    c.customer_status,

    count(o.order_id) as total_orders,

    countif(o.order_status = 'COMPLETED') as completed_orders,

    countif(o.order_status = 'CANCELLED') as cancelled_orders,

    countif(o.order_status = 'RETURNED') as returned_orders,

    sum(o.total_amount) as total_order_amount,

    sum(
        case
            when o.order_status = 'COMPLETED'
            then o.total_amount
            else 0
        end
    ) as completed_sales,

    avg(o.total_amount) as average_order_value

from {{ ref('stg_customers') }} c

left join {{ ref('stg_orders') }} o
    on c.customer_id = o.customer_id

group by
    c.customer_id,
    c.customer_name,
    c.city,
    c.state,
    c.customer_status