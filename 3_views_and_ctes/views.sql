-- Views for abstraction
-- This file contains SQL logic related to views for abstraction.

-- 1. Представление всех заказов с деталями клиента и товаров.
CREATE VIEW view_task_1 AS
SELECT
	o.id,
	o.order_date,
	c.first_name,
	c.last_name,
	p.name,
	p.category,
	oi.quantity,
	p.price,
	oi.price_at_order,
	o.total_amount
FROM order_items oi
JOIN orders o ON oi.order_id = o.id
JOIN products p ON oi.product_id = p.id
JOIN customers c ON o.customer_id = c.id
ORDER BY o.id;
	
-- 2. Представление активных клиентов (делали ≥ 3 заказов)
CREATE OR REPLACE VIEW v_active_customers AS
SELECT
  c.id,
  c.first_name,
  c.last_name,
  COUNT(o.id) AS total_orders
FROM customers c
JOIN orders o ON c.id = o.customer_id
GROUP BY c.id
HAVING COUNT(o.id) >= 3;

-- 3. Представление популярных товаров по количеству покупок
CREATE OR REPLACE VIEW v_popular_products AS
SELECT
  p.id,
  p.name,
  p.category,
  SUM(oi.quantity) AS total_sold
FROM products p
JOIN order_items oi ON p.id = oi.product_id
GROUP BY p.id
ORDER BY total_sold DESC;

-- 4. Представление заказов с итоговой суммой и количеством позиций
CREATE OR REPLACE VIEW v_orders_summary AS
SELECT
  o.id AS order_id,
  o.order_date,
  o.total_amount,
  COUNT(oi.id) AS total_items
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id;

-- 5. Представление всех заказов 2023 года
CREATE OR REPLACE VIEW v_orders_2023 AS
SELECT *
FROM orders
WHERE order_date LIKE '2023-%';

-- 6. Представление средней суммы заказа по клиенту
CREATE OR REPLACE VIEW v_avg_order_per_customer AS
SELECT
  c.id AS customer_id,
  c.first_name,
  c.last_name,
  ROUND(AVG(o.total_amount), 2) AS avg_order_amount
FROM customers c
JOIN orders o ON c.id = o.customer_id
GROUP BY c.id;

-- 7. Представление последних 10 заказов
CREATE OR REPLACE VIEW v_latest_orders AS
SELECT *
FROM orders
ORDER BY order_date DESC
LIMIT 10;

-- 8. Представление заказов с товарами из категории 'Electronics'
CREATE OR REPLACE VIEW v_orders_electronics AS
SELECT DISTINCT o.id AS order_id,
       o.order_date,
       c.first_name,
       c.last_name,
       p.name AS product_name
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE p.category = 'Electronics';

-- 9. Представление клиентов, заказавших более чем на 1000 у.е.
CREATE OR REPLACE VIEW v_high_value_customers AS
SELECT
  c.id,
  c.first_name,
  c.last_name,
  SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.id = o.customer_id
GROUP BY c.id
HAVING SUM(o.total_amount) > 1000;

-- 10. Представление заказов, в которых более 3 позиций
CREATE OR REPLACE VIEW v_large_orders AS
SELECT
  o.id AS order_id,
  COUNT(oi.id) AS total_items
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id
HAVING COUNT(oi.id) > 3;