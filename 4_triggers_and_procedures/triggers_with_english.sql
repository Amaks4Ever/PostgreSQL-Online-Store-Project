-- 						1 Create an AFTER INSERT trigger to log order item additions.
CREATE OR REPLACE FUNCTION orders_insert_trigger_1()
RETURNS TRIGGER AS $$
BEGIN 
	INSERT INTO logs(username, action, table_name, details)
	VALUES (
		CURRENT_USER,
		TG_OP,
		TG_TABLE_NAME,
		'Procut id: '||NEW.product_id||', Quantity: '||NEW.quantity
	);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_insert_trigger_1_activate
AFTER INSERT ON order_items
FOR EACH ROW 
EXECUTE FUNCTION orders_insert_trigger_1();

--Trigger Test price update trigger 1
INSERT INTO order_items(order_id, product_id, quantity)
VALUES(483, 183,2);

--Check that a log entry was added 
SELECT * FROM logs;


---- 2 Create a BEFORE INSERT trigger to reject unrealistic order values.
CREATE OR REPLACE FUNCTION orders_i_insert_trigger_2()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.price_at_order <= 0 THEN 
		RAISE EXCEPTION 'price at order must be greater than zero';
	END IF;
	IF NEW.quantity <= 0 THEN 
		RAISE EXCEPTION 'quantity must be greater than zero';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_i_insert_trigger_2_activate
BEFORE INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION orders_i_insert_trigger_2();

--Trigger Test price update trigger 2
INSERT INTO order_items(order_id, product_id, quantity, price_at_order)
VALUES(483, 182,1, -100);

----3 Log the email change only if the email was actually modified.	
CREATE OR REPLACE FUNCTION email_trigger_function_3()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.email IS DISTINCT FROM OLD.email THEN -- using IS DISTINCT FROM instead of <> to properly handle NULL values 
	INSERT INTO logs(username, action, table_name, details)
	VALUES (
		CURRENT_USER,
		TG_OP,
		TG_TABLE_NAME,
		'Email update. old email: '||OLD.email||', new email: '||NEW.email
	);
		END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_3
AFTER UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION email_trigger_function_3();

--Test price update trigger trigger 3
UPDATE customers 
SET email = 'mytriggerTest price update trigger@mail.com'
WHERE id = 1;

----4 Log the change of customer name if modified.
CREATE OR REPLACE FUNCTION username_trigger_function_4()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.first_name IS DISTINCT FROM OLD.first_name 
	OR NEW.last_name IS DISTINCT FROM OLD.last_name THEN -- using IS DISTINCT FROM instead of <> to properly handle NULL values 
	INSERT INTO logs(username, action, table_name, details)
	VALUES (
		CURRENT_USER,
		TG_OP,
		TG_TABLE_NAME,
		'Name update. old name: '||OLD.first_name||' '||OLD.last_name||
		', new name: '||NEW.first_name||' '||NEW.last_name
	);
		END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_4
AFTER UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION username_trigger_function_4();

--Test price update trigger
UPDATE customers
SET 
	first_name = 'Max',
	last_name = 'Zare'
WHERE id = 1;

--AFTER DELETE trigger to log order item deletions.
CREATE OR REPLACE FUNCTION delete_trigger_function_5()
RETURNS TRIGGER AS $$
BEGIN 
	INSERT INTO logs(username, action, table_name, details)
	VALUES (
		CURRENT_USER,
		TG_OP,
		TG_TABLE_NAME,
		'Deleted row - id: '||OLD.id||', order: '||OLD.order_id||
		', product id: '||OLD.product_id||', quantity: '||OLD.quantity||', price at order: '||OLD.price_at_order
	);
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_delete_5
AFTER DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION delete_trigger_function_5();

--Test price update trigger
DELETE FROM order_items WHERE id = 100;

--Trigger that updates 'total_amount' in orders upon insert, update, or delete in order_items.
CREATE OR REPLACE FUNCTION update_total_amount()
RETURNS TRIGGER AS $$
BEGIN
	UPDATE orders
	SET total_amount = (
		SELECT COALESCE(SUM(price_at_order), 0)
    	FROM order_items
    	WHERE order_id = COALESCE(NEW.order_id, OLD.order_id)
  )
  WHERE id = COALESCE(NEW.order_id, OLD.order_id);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_order_total
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION update_total_amount();

SELECT * FROM orders WHERE id = 1;
SELECT * FROM order_items WHERE order_id = 1;

--Prevent update of order_items if the order status is 'Completed'.
CREATE OR REPLACE FUNCTION prevent_update_if_order_completed()
RETURNS TRIGGER AS $$
DECLARE
  order_status TEXT;
BEGIN
  SELECT status INTO order_status
  FROM orders
  WHERE id = NEW.order_id;

  IF order_status = 'Completed' THEN
    RAISE EXCEPTION 'Update denied: order is completed.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_update_if_order_completed
BEFORE UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION prevent_update_if_order_completed();

--Test price update trigger
SELECT * FROM order_items WHERE order_id = 1659;
SELECT * FROM order_items WHERE order_id = 2159;

UPDATE order_items
SET quantity = 2
WHERE id = 35663;


--Trigger on products table that logs price changes.
CREATE OR REPLACE FUNCTION product_price_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if the price has changed
  IF NEW.price IS DISTINCT FROM OLD.price THEN
    -- Add a log entry
    INSERT INTO logs(username, action, table_name, details)
    VALUES (
      CURRENT_USER,
      TG_OP,
      TG_TABLE_NAME,
      'Product price update. old price: '||OLD.price||', new price: '||NEW.price
    );
    -- Update price_at_order for items of orders with status 'Pending'
    UPDATE order_items oi
    SET price_at_order = oi.quantity * NEW.price
    FROM orders o
    WHERE oi.order_id = o.id
      AND oi.product_id = NEW.id
      AND o.status = 'Pending';
    -- Update total order amount for orders with status 'Pending'
    UPDATE orders o
    SET total_amount = (
      SELECT SUM(price_at_order)
      FROM order_items
      WHERE order_id = o.id
    )
    WHERE o.status = 'Pending';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_price
AFTER UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION product_price_trigger_function();

--Test price update trigger 
UPDATE products
SET price = 249.04
WHERE id = 1;
