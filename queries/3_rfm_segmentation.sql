with customer_rfm_base as (
    select 
        c.customer_id,
        c.first_name || ' ' || c.last_name as full_name,
        c.email,
        extract(day from (current_date - max(r.rental_date)))::int as days_since_last_rental,
        count(distinct r.rental_id) as total_rentals,
        round(sum(p.amount)::numeric, 2) as total_spent,
        round(avg(p.amount)::numeric, 2) as avg_order_value,
        min(r.rental_date)::date as first_rental_date,
        max(r.rental_date)::date as last_rental_date
    from customer c
    join rental r on c.customer_id = r.customer_id 
    join payment p on r.rental_id = p.rental_id
    group by c.customer_id, c.first_name, c.last_name, c.email
),

customer_rfm_scores as (
    select 
        *,
        ntile(5) over (order by days_since_last_rental asc) as r_score,
        ntile(5) over (order by total_rentals desc) as f_score,
        ntile(5) over (order by total_spent desc) as m_score
    from customer_rfm_base
),

customer_segments as (
    select 
        *,
        r_score + f_score + m_score as rfm_total_score,
        concat(r_score, '-', f_score, '-', m_score) as rfm_code,
        case 
            when r_score >= 4 and f_score >= 4 and m_score >= 4
                then 'Best customers'
            when r_score >= 3 and f_score >= 4 and m_score >= 3
                then 'Loyal customers'
            when r_score >= 3 and m_score >= 4
                then 'Premium customers'
            when r_score >= 4 and f_score <= 2
                then 'New customers'
            when r_score <= 2 and f_score >= 3
                then 'No active customers'
            when r_score <= 2 and f_score <= 2
                then 'Lost customers'
            else 'Regular customers'
        end as segment
    from customer_rfm_scores
)

select 
    customer_id,
    full_name,
    email,
    days_since_last_rental as "дней с последней аренды",
    total_rentals as "всего аренд",
    total_spent as "всего потрачено",
    avg_order_value as "средний чек",
    r_score as "r",
    f_score as "f",
    m_score as "m",
    rfm_total_score as "rfm total",
    segment as "сегмент"
from customer_segments
order by rfm_total_score desc, total_spent desc;