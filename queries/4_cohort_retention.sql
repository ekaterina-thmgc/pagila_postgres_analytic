with customer_cohorts as (
    select 
        c.customer_id,
        date_trunc('month', min(r.rental_date)) as cohort_month,
        min(r.rental_date)::date as first_rental_date
    from customer c
    join rental r on c.customer_id = r.customer_id
    group by c.customer_id
),

rental_activity as (
    select 
        cc.customer_id,
        cc.cohort_month,
        date_trunc('month', r.rental_date) as activity_month,
        extract(month from age(date_trunc('month', r.rental_date), cc.cohort_month))::int as months_since_cohort,
        sum(p.amount) as monthly_revenue
    from customer_cohorts cc
    join rental r on cc.customer_id = r.customer_id
    join payment p on r.rental_id = p.rental_id
    group by cc.customer_id, cc.cohort_month, date_trunc('month', r.rental_date)
),

cohort_sizes as (
    select 
        cohort_month,
        count(distinct customer_id) as cohort_size
    from customer_cohorts
    group by cohort_month
),

cohort_retention as (
    select 
        ra.cohort_month,
        ra.months_since_cohort,
        count(distinct ra.customer_id) as active_customers,
        sum(ra.monthly_revenue) as cohort_revenue,
        avg(ra.monthly_revenue) as avg_revenue_per_customer
    from rental_activity ra
    group by ra.cohort_month, ra.months_since_cohort
)

select 
    to_char(cr.cohort_month, 'yyyy-mm') as "когорта",
    cr.months_since_cohort as "месяц",
    cs.cohort_size as "размер когорты",
    cr.active_customers as "активны",
    round(cr.active_customers * 100.0 / cs.cohort_size, 1) as "retention rate",
    round(cr.cohort_revenue::numeric, 2) as "выручка",
    repeat('█', (cr.active_customers * 20 / cs.cohort_size)::int) || 
    repeat('░', 20 - (cr.active_customers * 20 / cs.cohort_size)::int) as "визуализация"
from cohort_retention cr
join cohort_sizes cs on cr.cohort_month = cs.cohort_month
where cr.months_since_cohort <= 6
order by cr.cohort_month, cr.months_since_cohort;