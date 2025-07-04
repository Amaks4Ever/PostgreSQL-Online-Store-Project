-- Customer order number in order
SELECT 
c.first_name,
c.last_name,
o.id, 
o.order_date,
o.total_amount,
ROW_NUMBER() OVER (PARTITION BY c.first_name, c.last_name ORDER BY o.order_date)
FROM orders o
JOIN customers c ON o.customer_id = c.id;


-- Difference between product price and category average
SELECT 
name,
category,
price,
ROUND(AVG(price) OVER (PARTITION BY category),2) as avg_category_price,
price - ROUND(AVG(price) OVER (PARTITION BY category),2) as diff
FROM products;

-- Average order amount per customer
SELECT DISTINCT ON(c.first_name, c.last_name)
c.first_name,
c.last_name,
ROUND(AVG(o.total_amount) OVER (
	PARTITION BY c.first_name, c.last_name),2) as avg_sum_client
FROM orders o
JOIN customers c ON o.customer_id = c.id;

-- Top 3 most expensive products in each category
SELECT 
name,
category,
price
FROM (
	SELECT 
	name,
	category,
	price,
	RANK() OVER (
		PARTITION BY category 
		ORDER BY price DESC
		) as rnk
	FROM products
) as rank_table
WHERE rank_table.rnk <=3;

-- Average order amount over the customer's last 3 orders
SELECT 
c.first_name,
c.last_name,
avg_table.id,
avg_table.order_date,
avg_table.total_amount,
avg_table.avg_3_last_order
FROM(
	SELECT 
	customer_id as cid,
	id,
	order_date,
	total_amount,
	ROW_NUMBER() OVER (
		PARTITION BY customer_id
		) as rn,
	ROUND(AVG(total_amount) OVER (
		PARTITION BY customer_id
		ORDER BY order_date DESC
		ROWS BETWEEN 2 PRECEDING AND UNBOUNDED FOLLOWING
		),2) as avg_3_last_order
	FROM orders
) as avg_table
JOIN customers c ON avg_table.cid = c.id
WHERE avg_table.rn <=3;

-- Use LAG() to compare a customer's order amounts
SELECT
c.first_name,
c.last_name,
o.id,
o.order_date,
o.total_amount,
o.total_amount-LAG(o.total_amount) OVER (
	PARTITION BY c.first_name, c.last_name
	ORDER BY o.total_amount
)as diff
FROM orders o
JOIN customers c ON o.customer_id = c.id;

-- NTILE(4): Divide customers into order amount quartiles


SELECT
c.first_name,
c.last_name,
o.id,
o.order_date,
o.total_amount,
NTILE(4) OVER (
	PARTITION BY c.first_name, c.last_name
	ORDER BY o.order_date
) as customers_group
FROM orders o
JOIN customers c ON o.customer_id = c.id;

-- Compare each order to the previous one by date
SELECT
c.first_name,
c.last_name,
o.id,
o.order_date,
o.total_amount,
o.total_amount-LAG(o.total_amount) OVER (
	PARTITION BY c.first_name, c.last_name
	ORDER BY o.order_date
) as dif
FROM orders o
JOIN customers c ON o.customer_id = c.id;

-- Cumulative sum of products in each order
SELECT
oi.order_id,
p.name,
oi.quantity,
SUM(oi.quantity) OVER (
	PARTITION BY oi.order_id
	ORDER BY oi.quantity
	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) as sum_products_quantity
FROM order_items oi
JOIN products p ON oi.product_id = p.id;

-- Running total of customer's order amounts
SELECT
c.first_name,
c.last_name,
o.id,
o.order_date,
o.total_amount,
SUM(o.total_amount) OVER (
	PARTITION BY c.first_name, c.last_name
	ORDER BY o.order_date
	ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) as sum_total_amount_client
FROM orders o
JOIN customers c ON o.customer_id = c.id;