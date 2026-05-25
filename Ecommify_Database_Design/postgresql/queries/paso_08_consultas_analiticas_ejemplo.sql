-- Ecommify Database Design
-- Paso 08: consultas de ejemplo para validacion y analitica.
-- Objetivo: demostrar busqueda por ID Olist y joins mediante llaves tecnicas internas.
-- Ejecutar despues del paso 07 si se quieren consultar tableros.

SET search_path TO ecommify, public;

-- Detalle de una orden para validacion OLTP.
-- Reemplazar :order_id por un identificador Olist real si se ejecuta fuera de una herramienta con parametros.
SELECT
    o.order_sk,
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_id,
    c.customer_state,
    oi.order_item_id,
    p.product_id,
    s.seller_id,
    oi.price,
    oi.freight_value,
    op.payment_type,
    op.payment_value
FROM orders o
JOIN customers c ON c.customer_sk = o.customer_sk
LEFT JOIN order_items oi ON oi.order_sk = o.order_sk
LEFT JOIN products p ON p.product_sk = oi.product_sk
LEFT JOIN sellers s ON s.seller_sk = oi.seller_sk
LEFT JOIN order_payments op ON op.order_sk = o.order_sk
WHERE o.order_id = :order_id;

-- Tablero de ventas mensuales por categoria.
SELECT *
FROM mv_sales_by_category_monthly
ORDER BY sales_month DESC, gross_sales DESC;

-- Tablero de segmentacion de clientes.
SELECT *
FROM mv_customer_segments
ORDER BY total_payment_value DESC;
