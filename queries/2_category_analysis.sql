select 
	category_name as "Категория",
	film_count as "Фильмов",
	total_rentals as "Аренд",
	round(total_revenue::numeric,2) as "Выручка",
	unique_customer as "Клиентов",
	round(total_revenue *100.0 / sum(total_revenue) over(),2) as "Доля выручки",
	round((total_revenue /nullif(film_count,0))::numeric, 2) as "Выручка за один фильм категории",
	rank() over (order by total_revenue desc) as "Рейтинг",
	round(percent_rank () over (order by total_revenue desc )::numeric,2) as "Процентиль"
from (
	select 
		c.category_id,
		c.name as category_name,
		count (distinct f.film_id) as film_count,
		count (distinct r.rental_id) as total_rentals,
		coalesce(sum(p.amount),0) as total_revenue,
		coalesce(avg(p.amount),0) as avg_payment,
		count(distinct r.customer_id) as unique_customer
	from category c
	left join film_category fc on c.category_id = fc.category_id
	left join film f on fc.film_id = f.film_id
	left join inventory i on f.film_id = i.film_id
	left join rental r on i.inventory_id = r.inventory_id
	left join payment p on r.rental_id = p.rental_id
	group by c.category_id, c.name

) as category_metrics
order by total_revenue desc;
	
	