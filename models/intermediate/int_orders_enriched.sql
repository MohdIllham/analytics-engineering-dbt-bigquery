{{
    config(
        materialized='table',
        description="Enriched orders with items, payments, and reviews. One row per order-item.",
        indexes=[
            {'columns': ['order_id'], 'type': 'hash'},
            {'columns': ['product_id'], 'type': 'hash'}
        ]
    )
}}

with orders as (
    select
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_delivered_customer_date
    from {{ ref('stg_orders') }}
    where order_status not in ('canceled', 'unavailable')  -- optional filter
),

order_items as (
    select
        order_id,
        product_id,
        seller_id,
        price,
        freight_value
    from {{ ref('stg_order_items') }}
),

order_payments as (
    select
        order_id,
        payment_type,
        payment_value
    from {{ ref('stg_order_payments') }}
),

order_reviews as (
    select
        order_id,
        review_score
    from {{ ref('stg_order_reviews') }}
),

payment_agg as (
    select
        order_id,
        string_agg(distinct payment_type, ', ' order by payment_type) as payment_types,
        sum(payment_value) as total_payment,
        count(*) as payment_count
    from order_payments
    group by 1
),

review_agg as (
    select
        order_id,
        avg(review_score) as avg_review_score,
        min(review_score) as min_review_score,
        max(review_score) as max_review_score,
        count(*) as review_count
    from order_reviews
    group by 1
)

select
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    
    -- Item details (still multiple rows per order)
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    
    -- Aggregated payment info (same for all rows of same order)
    pa.payment_types,
    pa.total_payment,
    pa.payment_count,
    
    -- Aggregated review info
    ra.avg_review_score,
    ra.review_count,
    
    -- Derived metrics
    oi.price + oi.freight_value as total_item_amount,
    date(o.order_purchase_timestamp) as order_date

from orders o
inner join order_items oi
    on o.order_id = oi.order_id
left join payment_agg pa
    on o.order_id = pa.order_id
left join review_agg ra
    on o.order_id = ra.order_id