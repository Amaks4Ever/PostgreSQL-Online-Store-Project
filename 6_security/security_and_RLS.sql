-- Security and Row-Level Security
-- This file contains SQL logic related to security and row-level security.

--Включи Row Level Security (RLS) для таблицы заказов.
ALTER TABLE orders ENABLE ROW LEVEL SECURITY; 

--Настрой политику RLS: клиент может видеть только свои заказы.
CREATE POLICY customer_order_policy
ON orders
USING (customer_id::text = current_setting('app.customer_id'));

ALTER TABLE orders FORCE ROW LEVEL SECURITY;

--test
SET app.customer_id = '123';
SELECT * FROM orders;

--Настрой роль guest, которая видит только список товаров.
CREATE ROLE client_user LOGIN PASSWORD 'testpass';
GRANT SELECT ON orders TO client_user;

--Сделай пользователя, который может только SELECT в products.
CREATE ROLE product_viewer LOGIN PASSWORD '12345';

GRANT CONNECT ON DATABASE poligon TO product_viewer;

GRANT USAGE ON SCHEMA public TO product_viewer;

GRANT SELECT ON products TO product_viewer;

--Запрети INSERT/UPDATE в orders для роли guest.
REVOKE INSERT, UPDATE, DELETE ON orders FROM client_user;

GRANT SELECT ON orders TO client_user;

--Настрой RLS политику для order_items с фильтрацией по заказам пользователя.
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

--test
SET app.customer_id = '42';
SELECT * FROM orders;
SELECT * FROM order_items;

--Создай функцию регистрации, которая создаёт пользователя и даёт права.
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

--Сделай политику: только админ может видеть всех клиентов.
CREATE POLICY admin_only_customers
ON customers
FOR SELECT
TO god
USING (true);

CREATE POLICY self_only_customers
ON customers
FOR SELECT
TO client_user
USING (id::text = current_setting('app.customer_id'));

--Защити поля email (шифрование или маскирование).
CREATE OR REPLACE VIEW masked_customers AS
SELECT
  id,
  first_name,
  last_name,
  CONCAT(SUBSTRING(email, 1, 3), '***@***.com') AS masked_email,
  country
FROM customers;

--Role set
SET ROLE client_user;
RESET ROLE;
SELECT current_user ;