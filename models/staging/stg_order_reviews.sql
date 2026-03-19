with ranked as (
    select *,
           row_number() over(partition by review_id order by review_creation_date desc) as rn,
           cast(review_score as int64) as review_score_int
    from {{ source('olist_raw_data', 'order_reviews') }}
)

select
    review_id,
    order_id,
    review_score_int as review_score,
    review_comment_message,
    review_creation_date
from ranked
where rn = 1