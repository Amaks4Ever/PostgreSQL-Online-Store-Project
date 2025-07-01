-- Procedures and functions
-- This file contains SQL logic related to procedures and functions.

-- Функция: рассчитать итоговую стоимость заказа по ID.
CREATE OR REPLACE FUNCTION get_order_total(order_id INT)
RETURNS NUMERIC AS $$
DECLARE
  total NUMERIC;
BEGIN
  SELECT SUM(quantity * price_at_order)
  INTO total
  FROM order_items
  WHERE order_id = get_order_total.order_id;

  RETURN COALESCE(total, 0);
END;
$$ LANGUAGE plpgsql;

-- Функция: вернуть список заказов по клиенту.
CREATE OR REPLACE FUNCTION get_orders_by_customer(customer_id INT)
RETURNS TABLE(order_id INT, order_date VARCHAR, total NUMERIC, status VARCHAR) AS $$
BEGIN
  RETURN QUERY
  SELECT id, order_date, total_amount, status
  FROM orders
  WHERE customer_id = get_orders_by_customer.customer_id;
END;
$$ LANGUAGE plpgsql;

-- Процедура: массовое изменение категории товаров.
CREATE OR REPLACE PROCEDURE update_category_bulk(old_cat TEXT, new_cat TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE products
  SET category = new_cat
  WHERE category = old_cat;
END;
$$;

-- Функция: получить среднюю цену товаров по категории.
CREATE OR REPLACE FUNCTION avg_price_by_category(cat TEXT)
RETURNS NUMERIC AS $$
DECLARE
  result NUMERIC;
BEGIN
  SELECT AVG(price) INTO result
  FROM products
  WHERE category = cat;
  RETURN COALESCE(result, 0);
END;
$$ LANGUAGE plpgsql;

-- Процедура: добавить несколько заказов в одной транзакции.
CREATE OR REPLACE PROCEDURE insert_bulk_orders(customer_id INT, total1 NUMERIC, total2 NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO orders(customer_id, order_date, total_amount, status)
  VALUES 
    (customer_id, CURRENT_DATE, total1, 'Pending'),
    (customer_id, CURRENT_DATE, total2, 'Pending');
END;
$$;

-- Функция: проверить, делал ли клиент заказы в этом месяце.
CREATE OR REPLACE FUNCTION had_orders_this_month(c_id INT)
RETURNS BOOLEAN AS $$
DECLARE
  exists_orders BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM orders
    WHERE customer_id = c_id
    AND DATE_TRUNC('month', order_date::date) = DATE_TRUNC('month', CURRENT_DATE)
  ) INTO exists_orders;
  RETURN exists_orders;
END;
$$ LANGUAGE plpgsql;

-- Функция: возвращающая количество заказов по статусу.
CREATE OR REPLACE FUNCTION count_orders_by_status(status_name TEXT)
RETURNS INTEGER AS $$
DECLARE
  result INT;
BEGIN
  SELECT COUNT(*) INTO result
  FROM orders
  WHERE status = status_name;
  RETURN result;
END;
$$ LANGUAGE plpgsql;