select
    order_id,
    coalesce(payment_type,'unknown') as payment_type,
    payment_installments,
    payment_value
from {{ source('olist_raw_data','order_payments') }}