select
    order_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
from {{ source('olist_raw_data','order_items') }}