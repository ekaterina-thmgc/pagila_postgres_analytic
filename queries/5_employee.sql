select 
    s.staff_id,
    concat(s.first_name, ' ', s.last_name) as employee_name,
    s.email,
    st.store_id,
    count(distinct r.rental_id) as total_rentals,
    count(distinct r.customer_id) as unique_customers,
    round(sum(p.amount)::numeric, 2) as total_revenue,
    round(avg(p.amount)::numeric, 2) as avg_transaction,
    round(
        percentile_cont(0.5) within group (order by p.amount)::numeric, 
        2
    ) as median_transaction,
    round(
        sum(p.amount) * 100.0 / sum(sum(p.amount)) over(), 
        2
    ) as revenue_share_pct,
    rank() over (order by sum(p.amount) desc) as revenue_rank,
    round(
        sum(p.amount) / count(distinct r.customer_id)::numeric, 
        2
    ) as revenue_per_customer,
    min(r.rental_date)::date as first_sale,
    max(r.rental_date)::date as last_sale,
    count(distinct date(r.rental_date)) as active_days
from staff s
join store st on s.store_id = st.store_id
join rental r on s.staff_id = r.staff_id
join payment p on r.rental_id = p.rental_id
group by 
    s.staff_id, 
    s.first_name, 
    s.last_name, 
    s.email,
    st.store_id
order by total_revenue desc;