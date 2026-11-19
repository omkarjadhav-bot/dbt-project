{% set customer_status = var('customer_status', 'ACTIVE') %}

select
    customer_id,
    customer_name,
    city,
    state,
    signup_date,
    customer_status
from {{ ref('stg_customers') }}
where customer_status = '{{ customer_status }}'