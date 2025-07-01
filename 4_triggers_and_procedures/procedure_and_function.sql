-- Function: calculate the total cost of an order by ID.
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

-- Function: return a list of orders by customer.
CREATE OR REPLACE FUNCTION get_orders_by_customer(customer_id INT)
RETURNS TABLE(order_id INT, order_date VARCHAR, total NUMERIC, status VARCHAR) AS $$
BEGIN
  RETURN QUERY
  SELECT id, order_date, total_amount, status
  FROM orders
  WHERE customer_id = get_orders_by_customer.customer_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure: bulk update product category.
CREATE OR REPLACE PROCEDURE update_category_bulk(old_cat TEXT, new_cat TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE products
  SET category = new_cat
  WHERE category = old_cat;
END;
$$;

-- Function: get the average price of products in a category.
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

-- Procedure: insert multiple orders in one transaction.
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

-- Function: check if a customer has made orders this month.
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

-- Function: return the count of orders by status.
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
