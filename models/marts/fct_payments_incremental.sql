{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge',
        on_schema_change='fail',
        description="Incremental fact table for order payments",
        indexes=[
            {'columns': ['order_id'], 'type': 'hash'}
        ]
    )
}}

with source as (
    select
        order_id,
        payment_type,
        payment_value
    from {{ ref('stg_order_payments') }}
)

select
    order_id,
    payment_type,
    payment_value,
    current_timestamp as inserted_at
from source

{% if is_incremental() %}
where order_id not in (select order_id from {{ this }})
{% endif %}