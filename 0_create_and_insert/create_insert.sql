
-- Create table for storing customer information
CREATE TABLE customers(
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email TEXT,
    reg_date TIMESTAMP DEFAULT NOW(), -- registration date
    country VARCHAR(50)
);

-- Create table for storing product information
CREATE TABLE products(
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    price NUMERIC(10,2),
    category VARCHAR(30)
);

-- Create table for storing orders
CREATE TABLE orders(
    id SERIAL PRIMARY KEY,
    customer_id INT, -- references customers(id)
    order_date VARCHAR(50),
    total_amount NUMERIC(10,2),
    status VARCHAR(15)
);

-- Create table for storing order items (many-to-many relation between orders and products)
CREATE TABLE order_items(
    id SERIAL PRIMARY KEY,
    order_id INT,     -- references orders(id)
    product_id INT,   -- references products(id)
    quantity INT,
    price_at_order NUMERIC(10,2) -- price per item at the time of order
);

-- Create table for logging actions
CREATE TABLE logs(
    id SERIAL PRIMARY KEY,
    log_time TIMESTAMP DEFAULT NOW(), -- when the action occurred
    username TEXT,
    action TEXT,
    table_name TEXT,
    details TEXT
);

-- Insert mock data into customers table
INSERT INTO customers(first_name, last_name, email, reg_date, country)
SELECT
  INITCAP(SUBSTRING(md5(i::text), 1, 8)), -- random first name
  INITCAP(SUBSTRING(md5((i*13)::text), 1, 8)), -- random last name
  SUBSTRING(md5(i::text), 1, 8) || '@example.com', -- random email
  (CURRENT_DATE - (random()*365*5)::int * INTERVAL '1 day')::date, -- registration date up to 5 years ago
  CASE
    WHEN random() < 0.3 THEN 'USA'
    WHEN random() < 0.6 THEN 'Canada'
    ELSE 'Germany'
  END
FROM generate_series(1, 1000) AS i;

-- Insert mock data into products table
INSERT INTO products(name, price, category)
SELECT
  'Product_' || i,
  ROUND((random() * 500 + 10)::numeric, 2), -- random price between 10 and 510
  CASE
    WHEN i % 7 = 0 THEN 'Electronics'
    WHEN i %  7 = 1 THEN 'Books'
    WHEN i %  7 = 2 THEN 'Clothing'
    WHEN i %  7 = 3 THEN 'Home'
    WHEN i %  7 = 4 THEN 'Toys'
    WHEN i %  7 = 5 THEN 'Sports'
    WHEN i %  7 = 6 THEN 'Beauty'
  END
FROM generate_series(1, 200) AS i;

-- Insert mock data into orders table
INSERT INTO orders(customer_id, order_date, total_amount, status)
SELECT
  (random() * 999 + 1)::int, -- customer ID between 1 and 1000
  (CURRENT_DATE - (random() * 365 * 3)::int * INTERVAL '1 day')::date, -- order date up to 3 years ago
  ROUND((random() * 1000 + 20)::numeric, 2), -- total amount between 20 and 1020
  CASE
    WHEN random() < 0.7 THEN 'Completed'
    WHEN random() < 0.9 THEN 'Pending'
    ELSE 'Cancelled'
  END
FROM generate_series(1, 10000) AS i;

-- Insert mock data into order_items table
INSERT INTO order_items(order_id, product_id, quantity, price_at_order)
SELECT
  (random() * 9999 + 1)::int, -- order ID between 1 and 10000
  (random() * 199 + 1)::int, -- product ID between 1 and 200
  (random() * 5 + 1)::int, -- quantity between 1 and 5
  ROUND((random() * 500 + 10)::numeric, 2) -- price between 10 and 510
FROM generate_series(1, 100000) AS i;
