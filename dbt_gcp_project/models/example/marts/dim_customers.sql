select
    c.customer_id,
    c.customer_name,
    c.city,
    c.state,
    c.customer_status,

    s.signup_date,

    c.total_orders,
    c.completed_orders,
    c.cancelled_orders,
    c.returned_orders,

    c.total_order_amount,
    c.completed_sales,
    c.average_order_value,

    r.sales_rank

from {{ ref('int_customer_order_summary') }} c

left join {{ ref('int_customer_sales_rank') }} r
    on c.customer_id = r.customer_id

left join {{ ref('stg_customers') }} s
    on c.customer_id = s.customer_id