
-- Create indexes on order_items for faster join operations
CREATE INDEX idx_order_items_orders_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Update the price_at_order field by calculating quantity * product price
-- Only for orders with status 'Pending'
UPDATE order_items oi
SET price_at_order = oi.quantity * p.price
FROM products p, orders o
WHERE oi.product_id = p.id
  AND oi.order_id = o.id
  AND o.status = 'Pending';

-- Recalculate the total_amount for each order by summing price_at_order
UPDATE orders o
SET total_amount = (
	SELECT 
	SUM(price_at_order)
	FROM order_items
	WHERE order_id = o.id
);
