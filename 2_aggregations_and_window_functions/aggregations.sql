
-- Total sum of all orders.
SELECT 
	SUM(total_amount)
FROM orders;

-- Average number of items per order.
WITH count_orders AS (
	SELECT 
		COUNT(*) as avg_count	
	FROM order_items
	GROUP BY order_id
)
SELECT 
	ROUND(AVG(avg_count))
FROM count_orders;

-- Number of customers from each country.
SELECT 
	country,
	COUNT(*) 
FROM customers
GROUP BY country;

-- Average product price in each category.
SELECT 
	category,
	ROUND(AVG(price),2) as avg_price
FROM products
GROUP BY category
ORDER BY avg_price DESC ;

-- Most ordered products (Top 5).
SELECT
	p.name,
	SUM(oi.quantity) as sum_product
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY p.name
ORDER BY SUM(oi.quantity) DESC LIMIT 5;

-- Customers with total orders over $1000.
SELECT 
	c.first_name,
	c.last_name,
	SUM(o.total_amount) as total_sum
FROM orders o
JOIN customers c ON o.customer_id = c.id
GROUP BY c.first_name, c.last_name 
HAVING SUM(o.total_amount)>1000;

-- Categories with average price over $240.
SELECT 
	category,
	ROUND(AVG(price),2) AS avg_price
FROM products
GROUP BY category 
HAVING AVG(price)>240;

-- Products sold in more than 500 orders.
SELECT 
	p.name,
	COUNT(oi.order_id) as count_o
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY p.name HAVING COUNT(oi.order_id)> 500
ORDER BY count_o;

-- Number of orders by month.
SELECT 
TO_CHAR(order_date::DATE, 'YYYY-MM') as order_date,
COUNT(*) as orders_count
FROM orders
GROUP BY TO_CHAR(order_date::DATE, 'YYYY-MM')
ORDER BY order_date;

-- Customers with more than 5 orders.
SELECT 
c.first_name,
c.last_name,
COUNT(o.id) as count_orders
FROM orders o
JOIN customers c ON o.customer_id = c.id
GROUP BY c.first_name, c.last_name HAVING COUNT(o.id)>10
ORDER BY count_orders;
