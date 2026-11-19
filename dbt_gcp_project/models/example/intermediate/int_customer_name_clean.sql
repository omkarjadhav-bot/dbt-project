{{ config(materialized='table') }}

select
    customer_id,

    {{ clean_string('customer_name') }} as cleaned_customer_name,

    city,
    state

from {{ ref('stg_customers') }}