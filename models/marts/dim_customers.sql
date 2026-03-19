{{
    config(
        materialized='table',
        description="Customer dimension table with unique customers per row",
        unique_key='customer_id'
    )
}}

with ranked_customers as (
    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        
        -- Optional: Add derived columns
        case
            when customer_state in ('SP', 'RJ', 'MG') then 'Southeast'
            when customer_state in ('PR', 'SC', 'RS') then 'South'
            when customer_state in ('BA', 'PE', 'CE') then 'Northeast'
            else 'Other'
        end as customer_region,
        
        current_timestamp as dim_updated_at,
        
        -- Untuk pilih satu row per customer_unique_id
        row_number() over (
            partition by customer_unique_id 
            order by customer_id
        ) as rn

    from {{ ref('stg_customers') }}
)

select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    customer_region,
    dim_updated_at
from ranked_customers
where rn = 1  