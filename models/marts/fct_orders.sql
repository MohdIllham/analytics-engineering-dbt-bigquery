{{
    config(
        materialized='table',
        description="Fact table for orders with metrics and foreign keys",
        unique_key='order_id'
    )
}}

with orders as (
    select * from {{ ref('stg_orders') }}
),

items_agg as (
    select
        order_id,
        ANY_VALUE(product_id) as product_id,
        ANY_VALUE(seller_id) as seller_id,
        sum(price) as price,
        sum(freight_value) as freight_value
    from {{ ref('stg_order_items') }}
    group by 1
),

payments_agg as (
    select
        order_id,
        ANY_VALUE(payment_type) as payment_type
    from {{ ref('stg_order_payments') }}
    group by 1
),

reviews_agg as (
    select
        order_id,
        -- Kita paksa dia jadi STRING terus kat sini dan bagi alias 'review_score'
        CAST(ANY_VALUE(review_score) AS STRING) as review_score 
    from {{ ref('stg_order_reviews') }}
    group by 1
)

select
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp as order_date, 
    i.product_id,
    i.seller_id,
    i.price,
    i.freight_value,
    p.payment_type,
    -- Dekat sini AMBIL SAHAJA, jangan CAST balik jadi INT64!
    r.review_score 

from orders o
left join items_agg i on o.order_id = i.order_id
left join payments_agg p on o.order_id = p.order_id
left join reviews_agg r on o.order_id = r.order_id
