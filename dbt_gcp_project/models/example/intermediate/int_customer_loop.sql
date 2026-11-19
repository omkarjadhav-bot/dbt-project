{% set columns = [
    'customer_id',
    'customer_name',
    'city',
    'state'
] %}

select
    {% for column in columns %}
        {{ column }}{% if not loop.last %},{% endif %}
    {% endfor %}
from {{ ref('stg_customers') }}