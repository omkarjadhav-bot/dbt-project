{{ config(materialized='view') }}

select
    customer_id,
    customer_name,
    city,
    state,
    signup_date,
    customer_status
from {{ source('raw', 'raw_customers') }}