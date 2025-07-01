-- Aggregations and groupings
-- This file contains SQL logic related to aggregations and groupings.

--Общая сумма всех заказов.
SELECT 
	SUM(total_amount)
FROM orders;

--Среднее количество позиций в заказе.
WITH count_orders AS (
	SELECT 
		COUNT(*) as avg_count	
	FROM order_items
	GROUP BY order_id
)
SELECT 
	ROUND(AVG(avg_count))
FROM count_orders;

--Количество клиентов из каждой страны.
SELECT 
	country,
	COUNT(*) 
FROM customers
GROUP BY country;

--Средняя цена товаров в каждой категории.
SELECT 
	category,
	ROUND(AVG(price),2) as avg_price
FROM products
GROUP BY category
ORDER BY avg_price DESC ;

--Самые заказываемые товары (топ 5).
SELECT
	p.name,
	SUM(oi.quantity) as sum_product
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY p.name
ORDER BY SUM(oi.quantity) DESC LIMIT 5;


--Клиенты с суммой заказов больше $1000.
SELECT 
	c.first_name,
	c.last_name,
	SUM(o.total_amount) as total_sum
FROM orders o
JOIN customers c ON o.customer_id = c.id
GROUP BY c.first_name, c.last_name 
HAVING SUM(o.total_amount)>1000;

--Категории, в которых средняя цена товара больше $240.
SELECT 
	category,
	ROUND(AVG(price),2) AS avg_price
FROM products
GROUP BY category 
HAVING AVG(price)>240;

--Продукты, проданные более чем в 500 заказах.
SELECT 
	p.name,
	COUNT(oi.order_id) as count_o
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY p.name HAVING COUNT(oi.order_id)> 500
ORDER BY count_o;

--Кол-во заказов по месяцам.
SELECT 
TO_CHAR(order_date::DATE, 'YYYY-MM') as order_date,
COUNT(*) as orders_count
FROM orders
GROUP BY TO_CHAR(order_date::DATE, 'YYYY-MM')
ORDER BY order_date;

--Кол-во заказов у клиентов, у которых более 5 заказов.
SELECT 
c.first_name,
c.last_name,
COUNT(o.id) as count_orders
FROM orders o
JOIN customers c ON o.customer_id = c.id
GROUP BY c.first_name, c.last_name HAVING COUNT(o.id)>10
ORDER BY count_orders;
