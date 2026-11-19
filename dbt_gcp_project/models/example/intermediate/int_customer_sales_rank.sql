select
    customer_id,
    customer_name,
    city,
    customer_status,
    completed_sales,

    rank() over (
        order by completed_sales desc
    ) as sales_rank

from {{ ref('int_customer_order_summary') }}