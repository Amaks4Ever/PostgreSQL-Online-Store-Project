-- Display first names and emails of all customers
-- This is a basic SELECT query from the customers table
SELECT 
    first_name,
    email
FROM customers;

-- List all orders with their date and total amount
-- Shows order details from the orders table
SELECT 
    id,
    order_date,
    total_amount
FROM orders;

-- List products that have been ordered at least once
-- Uses EXISTS to check if the product ID is used in the order_items table
SELECT 
    name
FROM products p
WHERE EXISTS (
    SELECT 1
    FROM order_items oi 
    WHERE oi.product_id = p.id
);

-- List of customers with the number of their orders
-- Performs a JOIN and aggregates with COUNT
SELECT 
    c.first_name,
    c.last_name,
    COUNT(o.id) AS orders_count
FROM orders o
JOIN customers c ON o.customer_id = c.id
GROUP BY c.first_name, c.last_name;

-- List customers and total number of items in their orders
-- Aggregates SUM over joined orders and order_items
SELECT 
    c.first_name,
    c.last_name,
    SUM(oi.quantity) AS sum_products_quantity
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN order_items oi ON o.id = oi.order_id
GROUP BY c.first_name, c.last_name;

-- Top 10 most expensive products
-- Orders by price in descending order and limits results
SELECT
    name,
    price
FROM products
ORDER BY price DESC 
LIMIT 10;

-- All products from the "Electronics" category
-- Filters using WHERE with LIKE
SELECT 
    name, 
    category
FROM products
WHERE category LIKE 'Electronics';

-- List of customers who placed orders in January 2023
-- Uses TO_CHAR to extract year and month from order_date
SELECT 
    c.first_name, 
    c.last_name,
    TO_CHAR(o.order_date::DATE, 'YYYY-MM') as order_date
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE TO_CHAR(o.order_date::DATE, 'YYYY-MM') LIKE '2023-01';

-- The cheapest product in each category
-- Uses a correlated subquery to compare prices
SELECT 
    name,
    category,
    price
FROM products p1
WHERE price = (
    SELECT MIN(price)
    FROM products p2
    WHERE p2.category = p1.category
);

-- Orders that contain more than 3 items
-- Filters with HAVING on aggregated count
SELECT 
    order_id,
    COUNT(order_id) as count_orders
FROM order_items
GROUP BY order_id 
HAVING COUNT(order_id) > 3
ORDER BY count_orders;
