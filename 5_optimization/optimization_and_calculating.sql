-- Optimization and calculation logic
-- This file contains SQL logic related to optimization and calculation logic.

CREATE INDEX idx_order_items_orders_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

UPDATE order_items oi
SET price_at_order = oi.quantity * p.price
FROM products p, orders o
WHERE oi.product_id = p.id
  AND oi.order_id = o.id
  AND o.status = 'Pending';

UPDATE orders o
SET total_amount = (
	SELECT 
	SUM(price_at_order)
	FROM order_items
	WHERE order_id = o.id
);

