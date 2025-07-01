
-- Enable Row Level Security (RLS) for the orders table
ALTER TABLE orders ENABLE ROW LEVEL SECURITY; 

-- Create RLS policy: customers can only see their own orders
CREATE POLICY customer_order_policy
ON orders
USING (customer_id::text = current_setting('app.customer_id'));

ALTER TABLE orders FORCE ROW LEVEL SECURITY;

-- Test the policy by setting app.customer_id and querying orders
SET app.customer_id = '123';
SELECT * FROM orders;

-- Create a client_user role that can only view the list of orders
CREATE ROLE client_user LOGIN PASSWORD 'testpass';
GRANT SELECT ON orders TO client_user;

-- Create a product_viewer user who can only perform SELECT on products
CREATE ROLE product_viewer LOGIN PASSWORD '12345';

GRANT CONNECT ON DATABASE poligon TO product_viewer;
GRANT USAGE ON SCHEMA public TO product_viewer;
GRANT SELECT ON products TO product_viewer;

-- Revoke modification permissions on orders from client_user
REVOKE INSERT, UPDATE, DELETE ON orders FROM client_user;
GRANT SELECT ON orders TO client_user;

-- Set up RLS policy for order_items filtering by the user's orders
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY rls_items_per_customer
ON order_items
FOR SELECT 
USING (
    EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.id = order_items.order_id AND o.customer_id::text = current_setting('app.customer_id')
    )
);

GRANT SELECT ON order_items TO client_user; 

-- Test RLS on order_items
SET app.customer_id = '42';
SELECT * FROM orders;
SELECT * FROM order_items;

-- Create a registration function that creates a user and assigns permissions
CREATE OR REPLACE FUNCTION register_customer_user(customer_id INT, login TEXT, pass TEXT)
RETURNS void AS $$
BEGIN
  EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', login, pass);
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', current_database(), login);
  EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', login);
  EXECUTE format('GRANT SELECT ON products TO %I', login);
  EXECUTE format('GRANT SELECT ON orders TO %I', login);
  EXECUTE format('GRANT SELECT ON order_items TO %I', login);
  EXECUTE format('ALTER ROLE %I SET app.customer_id = %L', login, customer_id::text);
END;
$$ LANGUAGE plpgsql;

-- Create a policy: only admin (god) can view all customers
CREATE POLICY admin_only_customers
ON customers
FOR SELECT
TO god
USING (true);

-- Create a policy: regular users can only view their own data
CREATE POLICY self_only_customers
ON customers
FOR SELECT
TO client_user
USING (id::text = current_setting('app.customer_id'));

-- Protect email field using masking
CREATE OR REPLACE VIEW masked_customers AS
SELECT
  id,
  first_name,
  last_name,
  CONCAT(SUBSTRING(email, 1, 3), '***@***.com') AS masked_email,
  country
FROM customers;

-- Set and reset role to test access
SET ROLE client_user;
RESET ROLE;
SELECT current_user;
