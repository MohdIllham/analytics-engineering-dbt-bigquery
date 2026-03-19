{{
    config(
        materialized='table',
        description="Product dimension table with categories and physical attributes",
        unique_key='product_id',
        indexes=[
            {'columns': ['product_category_name'], 'type': 'hash'}
        ]
    )
}}

select
    p.product_id,
    coalesce(p.product_category_name,'uknown') as product_category_name,
    coalesce(pc.product_category_name_english,'unknown') as product_category_name_english,
    
    -- Fix typo: lenght → length
    p.product_name_lenght as product_name_length,
    p.product_description_lenght as product_description_length,
    p.product_photos_qty,
    
    -- Physical attributes
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    
    -- Derived metrics (optional tapi power)
    round(p.product_weight_g / 1000.0, 2) as product_weight_kg,
    round(p.product_length_cm * p.product_height_cm * p.product_width_cm / 1000.0, 2) as product_volume_liters,
    
    -- Categorize by size
    case
        when p.product_weight_g < 200 then 'Light'
        when p.product_weight_g between 200 and 1000 then 'Medium'
        else 'Heavy'
    end as weight_category,
    
    -- Tracking
    current_timestamp as dim_updated_at

from {{ ref('stg_products') }} p
left join {{ ref('stg_product_category') }} pc
    on p.product_category_name = pc.product_category_name