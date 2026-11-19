{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge'
) }}

select
    order_id,
    customer_id,
    order_date,
    order_status,
    payment_method,
    total_amount,
    updated_at
from {{ source('raw', 'raw_orders') }}

{% if is_incremental() %}
    where updated_at >= (
        select timestamp_sub(max(updated_at), interval 3 day)
        from {{ this }}
    )
{% endif %}