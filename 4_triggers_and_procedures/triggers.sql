-- Triggers for automatic logic
-- This file contains SQL logic related to triggers for automatic logic.

-- 						1 Создать AFTER INSERT триггер, логирующий добавление заказа.
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

--trigger test 1
INSERT INTO order_items(order_id, product_id, quantity)
VALUES(483, 183,2);

--проверяем добавление записи в логи 
SELECT * FROM logs;


---- 2 Сделать BEFORE INSERT, который отменяет заказ, если сумма нереальна.
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

--trigger test 2
INSERT INTO order_items(order_id, product_id, quantity, price_at_order)
VALUES(483, 182,1, -100);

----3 Логируй изменение email'а только если он изменился.	
CREATE OR REPLACE FUNCTION email_trigger_function_3()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.email IS DISTINCT FROM OLD.email THEN -- использую IS DISTINCT FROM вместо <> потому, что он позволяет функции корректно обрабатывать значения NULL 
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

--test trigger 3
UPDATE customers 
SET email = 'mytriggertest@mail.com'
WHERE id = 1;

----4 Добавь лог на изменение имени пользователя.
CREATE OR REPLACE FUNCTION username_trigger_function_4()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.first_name IS DISTINCT FROM OLD.first_name 
	OR NEW.last_name IS DISTINCT FROM OLD.last_name THEN -- использую IS DISTINCT FROM вместо <> потому, что он позволяет функции корректно обрабатывать значения NULL 
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

--test
UPDATE customers
SET 
	first_name = 'Max',
	last_name = 'Zare'
WHERE id = 1;

--Реализация AFTER DELETE, который логирует удаление заказа.
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

--test
DELETE FROM order_items WHERE id = 100;

--Сделание триггера, обновляющий поле total_amount в orders при вставке, обновлении или удаления в таблице order_items.
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

--Запрети обновление заказа, если его статус Completed.
CREATE OR REPLACE FUNCTION prevent_update_if_order_completed()
RETURNS TRIGGER AS $$
DECLARE
  order_status TEXT;
BEGIN
  SELECT status INTO order_status
  FROM orders
  WHERE id = NEW.order_id;

  IF order_status = 'Completed' THEN
    RAISE EXCEPTION 'Обновление запрещено: заказ завершён.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_update_if_order_completed
BEFORE UPDATE ON order_items
FOR EACH ROW
EXECUTE FUNCTION prevent_update_if_order_completed();

--test
SELECT * FROM order_items WHERE order_id = 1659;
SELECT * FROM order_items WHERE order_id = 2159;

UPDATE order_items
SET quantity = 2
WHERE id = 35663;


--Сделай триггер на таблицу products, который создаёт лог изменения цены.
CREATE OR REPLACE FUNCTION product_price_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  -- Проверяем, изменилась ли цена
  IF NEW.price IS DISTINCT FROM OLD.price THEN
    -- Добавляем запись в лог
    INSERT INTO logs(username, action, table_name, details)
    VALUES (
      CURRENT_USER,
      TG_OP,
      TG_TABLE_NAME,
      'Product price update. old price: '||OLD.price||', new price: '||NEW.price
    );
    -- Обновляем price_at_order только для заказов, где статус false
    UPDATE order_items oi
    SET price_at_order = oi.quantity * NEW.price
    FROM orders o
    WHERE oi.order_id = o.id
      AND oi.product_id = NEW.id
      AND o.status = 'Pending';
    -- Обновляем сумму заказов только для тех, где status = false
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

--test 
UPDATE products
SET price = 249.04
WHERE id = 1;
