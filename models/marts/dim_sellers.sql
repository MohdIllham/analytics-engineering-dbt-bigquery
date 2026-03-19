{{
    config(
        materialized='table',
        description="Seller dimension table with geographic info",
        unique_key='seller_id',
        indexes=[
            {'columns': ['seller_state'], 'type': 'hash'}
        ]
    )
}}

select
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    
    -- Derived columns untuk regional analysis
    case
        when seller_state in ('SP', 'RJ', 'MG') then 'Southeast'
        when seller_state in ('PR', 'SC', 'RS') then 'South'
        when seller_state in ('BA', 'PE', 'CE') then 'Northeast'
        when seller_state in ('DF', 'GO', 'MT', 'MS') then 'Central-West'
        when seller_state in ('AM', 'PA', 'RO', 'RR', 'AC', 'AP', 'TO') then 'North'
        else 'Other'
    end as seller_region,
    
    -- Tracking
    current_timestamp as dim_updated_at

from {{ ref('stg_sellers') }}