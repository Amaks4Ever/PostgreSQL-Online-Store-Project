
-- 1. View of all orders with customer and product details
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

-- 2. View of active customers (who placed 3 or more orders)
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

-- 3. View of popular products based on quantity sold
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

-- 4. View summarizing each order with total amount and item count
CREATE OR REPLACE VIEW v_orders_summary AS
SELECT
  o.id AS order_id,
  o.order_date,
  o.total_amount,
  COUNT(oi.id) AS total_items
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id;

-- 5. View of orders placed in 2023
CREATE OR REPLACE VIEW v_orders_2023 AS
SELECT *
FROM orders
WHERE order_date LIKE '2023-%';

-- 6. View of average order amount per customer
CREATE OR REPLACE VIEW v_avg_order_per_customer AS
SELECT
  c.id AS customer_id,
  c.first_name,
  c.last_name,
  ROUND(AVG(o.total_amount), 2) AS avg_order_amount
FROM customers c
JOIN orders o ON c.id = o.customer_id
GROUP BY c.id;

-- 7. View of the 10 most recent orders
CREATE OR REPLACE VIEW v_latest_orders AS
SELECT *
FROM orders
ORDER BY order_date DESC
LIMIT 10;

-- 8. View of orders that include products from the 'Electronics' category
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

-- 9. View of customers who spent more than 1000 currency units
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

-- 10. View of orders with more than 3 items
CREATE OR REPLACE VIEW v_large_orders AS
SELECT
  o.id AS order_id,
  COUNT(oi.id) AS total_items
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id
HAVING COUNT(oi.id) > 3;
