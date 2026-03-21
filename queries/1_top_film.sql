select 
	f.title,
	c.name,
	f.rating,
	f.rental_rate,
	f.length,
count(distinct r.rental_id) as total_rentals,
count(distinct i.inventory_id) as copies_in_stock,
round(sum(p.amount)::numeric,2) as total_revenue,
round(avg(p.amount)::numeric,2) as avg_payment,
round(
	sum(p.amount)*100.0 / sum(sum(p.amount)) over(),
	2) as revenue_share_pct,
rank() OVER (ORDER BY SUM(p.amount) DESC) AS revenue_rank
from film f
join film_category fc on f.film_id = fc.film_id
join category c on fc.category_id = c.category_id
join inventory i on f.film_id = i.film_id
join rental r on i.inventory_id=r.inventory_id
join payment p on r.rental_id=p.rental_id
group by 
	f.film_id,
	f.title,
	c.name,
	f.rental_rate,
	f.length
order by total_revenue desc 
limit 10;