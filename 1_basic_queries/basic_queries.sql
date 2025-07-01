-- Basic SELECT queries
-- This file contains SQL logic related to basic select queries.


--Вывести имена и почты всех клиентов.
SELECT 
	first_name,
	email
FROM customers;

--Список всех заказов с датой и суммой.
SELECT 
	id,
	order_date,
	total_amount
FROM orders;

--Список продуктов, заказанных хотя бы раз.
SELECT 
	name
	FROM products p
WHERE EXISTS(
	SELECT 1
	FROM order_items oi WHERE oi.product_id = p.id
);

--Список клиентов с указанием количества их заказов.
SELECT 
	c.first_name,
	c.last_name,
	COUNT(o.id) AS orders_count
FROM orders o
JOIN customers c ON o.customer_id = c.id
GROUP BY c.first_name, c.last_name ;

--Список клиентов и общее количество товаров в их заказах.
SELECT 
	c.first_name,
	c.last_name,
	SUM(oi.quantity) AS sum_products_quantity
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN order_items oi ON o.id = oi.order_id
GROUP BY c.first_name, c.last_name;

--Самые дорогие 10 товаров.
SELECT
	name,
	price
FROM products
ORDER BY price DESC 
LIMIT 10;

--Все продукты из категории "Electronics".
SELECT 
name, 
category
FROM products
WHERE category LIKE 'Electronics';

--Список клиентов, оформивших заказы в январе 2023 года.
SELECT 
c.first_name, 
c.last_name,
TO_CHAR(o.order_date::DATE, 'YYYY-MM') as order_date
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE TO_CHAR(o.order_date::DATE, 'YYYY-MM') LIKE '2023-01';

--Самый дешёвый товар в каждой категории.
SELECT 
name,
category,
price
FROM products p1
WHERE price = (
	SELECT
	MIN(price)
	FROM products p2
	WHERE p2.category = p1.category
);

--Заказы, в которых больше 3 позиций.
SELECT 
order_id,
COUNT(order_id) as count_orders
FROM order_items
GROUP BY order_id HAVING COUNT(order_id)>3
ORDER BY count_orders;



