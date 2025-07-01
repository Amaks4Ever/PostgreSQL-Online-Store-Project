-- Subqueries and their uses
-- This file contains SQL logic related to subqueries and their uses.

--Найти клиентов, которые сделали заказ на сумму выше средней
SELECT 
o.id as order_num,
c.first_name,
c.last_name,
o.total_amount,
ROUND((SELECT AVG(total_amount) FROM orders),2) as avg_total
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE total_amount>ROUND((SELECT AVG(total_amount) FROM orders),2);

--Продукты дороже среднего по своей категории 
SELECT 
p.name,
p.price,
ROUND((SELECT AVG(price) FROM products WHERE category = p.category),2) as customer_total
FROM products p
WHERE p.price > ROUND((SELECT AVG(price) FROM products WHERE category = p.category),2);

--Клиенты не заказавшие продукты из категории books
SELECT 
c.first_name,
c.last_name
FROM customers c
WHERE NOT EXISTS(
	SELECT 1
	FROM order_items oi
	JOIN orders o ON oi.order_id = o.id
	JOIN products p ON oi.product_id = p.id
	WHERE o.customer_id = c.id AND p.category LIKE 'Books'
);


--Самый дорогой товар в каждой категории
SELECT 
p.name,
(SELECT MAX(price) FROM products WHERE category = p.category) as category_max_price
FROM products p
WHERE p.price = (SELECT MAX(price) FROM products WHERE category = p.category);

--Заказы, где есть хотябы один товар дешевле 20$
SELECT 
o.id,
o.order_date
FROM orders o
WHERE EXISTS (
	SELECT 1
	FROM order_items oi
	JOIN products p ON oi.product_id = p.id
	WHERE oi.order_id = o.id AND p.price < 20
);


--Клиенты, заказывшие ровно один раз
SELECT 
c.first_name,
c.last_name
FROM customers c
WHERE c.id IN (
	SELECT 
	customer_id
	FROM orders 
	GROUP BY customer_id HAVING COUNT(*) = 1
); 

--Продукты, которые никогда не заказывали
SELECT 
p.name
FROM products p
WHERE NOT EXISTS(
	SELECT 1
	FROM order_items oi
	WHERE oi.product_id = p.id
);

--Последний заказ каждого клиента
SELECT
o1.customer_id,
o1.id,
o1.order_date as last_order_date
FROM orders o1
WHERE o1.order_date = (
	SELECT
	MAX(o2.order_date) 
	FROM orders o2
	WHERE o2.customer_id = o1.customer_id
);

--Самый первый заказ каждого клиента
SELECT
o1.customer_id,
o1.id,
o1.order_date as firs_order_date
FROM orders o1
WHERE o1.order_date = (
	SELECT
	MIN(o2.order_date) 
	FROM orders o2
	WHERE o2.customer_id = o1.customer_id
);

--Топ-3 самых продаваемых продукта по количеству заказов
SELECT
name
FROM products
WHERE id IN (
	SELECT 
	product_id
	FROM order_items
	GROUP BY product_id
	ORDER BY COUNT(*) DESC LIMIT 3
);
	