-- Ecommify Database Design
-- Paso 08: consultas de ejemplo para validacion y analitica.

SET search_path TO ecommify, public;

-- Detalle de una orden para validacion OLTP.
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_state,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value,
    op.payment_type,
    op.payment_value
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN order_payments op ON op.order_id = o.order_id
WHERE o.order_id = :order_id;

-- Dashboard de ventas mensuales.
SELECT *
FROM mv_sales_by_category_monthly
ORDER BY sales_month DESC, gross_sales DESC;

-- Dashboard de segmentacion de clientes.
SELECT *
FROM mv_customer_segments
ORDER BY total_payment_value DESC;

