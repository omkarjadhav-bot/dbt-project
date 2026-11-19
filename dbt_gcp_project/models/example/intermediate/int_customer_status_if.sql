{% set customer_status = var('customer_status', 'ACTIVE') %}

{% if customer_status == 'ACTIVE' %}

    select *
    from {{ ref('stg_customers') }}
    where customer_status = 'ACTIVE'

{% else %}

    select *
    from {{ ref('stg_customers') }}
    where customer_status = 'INACTIVE'

{% endif %}