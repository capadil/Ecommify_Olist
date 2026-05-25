-- Ecommify Database Design
-- Paso 05: crear vistas materializadas para dashboards OLAP.
-- Estas vistas evitan ejecutar consultas pesadas de dashboard sobre tablas OLTP.

SET search_path TO ecommify, public;

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_sales_by_category_monthly AS
SELECT
    date_trunc('month', o.order_purchase_timestamp)::date AS sales_month,
    COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS category_name,
    COUNT(DISTINCT o.order_id) AS orders_count,
    COUNT(*) AS items_count,
    SUM(oi.price) AS gross_sales,
    SUM(oi.freight_value) AS freight_total,
    SUM(oi.price + oi.freight_value) AS total_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN products p ON p.product_id = oi.product_id
LEFT JOIN category_translation ct ON ct.product_category_name = p.product_category_name
GROUP BY 1, 2
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_sales_by_category_monthly
    ON mv_sales_by_category_monthly (sales_month, category_name);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_customer_segments AS
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS orders_count,
    COALESCE(SUM(op.payment_value), 0) AS total_payment_value,
    MIN(o.order_purchase_timestamp) AS first_order_at,
    MAX(o.order_purchase_timestamp) AS last_order_at,
    AVG(r.review_score) AS avg_review_score,
    CASE
        WHEN COALESCE(SUM(op.payment_value), 0) >= 1000 THEN 'high_value'
        WHEN COUNT(DISTINCT o.order_id) >= 3 THEN 'repeat_customer'
        ELSE 'standard'
    END AS customer_segment
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
LEFT JOIN order_payments op ON op.order_id = o.order_id
LEFT JOIN order_reviews r ON r.order_id = o.order_id
GROUP BY c.customer_id, c.customer_unique_id, c.customer_state
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_customer_segments
    ON mv_customer_segments (customer_id);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_seller_performance_monthly AS
SELECT
    date_trunc('month', o.order_purchase_timestamp)::date AS sales_month,
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS orders_count,
    COUNT(*) AS items_count,
    SUM(oi.price) AS gross_sales,
    AVG(r.review_score) AS avg_review_score
FROM sellers s
JOIN order_items oi ON oi.seller_id = s.seller_id
JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN order_reviews r ON r.order_id = o.order_id
GROUP BY 1, 2, 3
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_seller_performance_monthly
    ON mv_seller_performance_monthly (sales_month, seller_id);

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_geo_sales_summary AS
SELECT
    c.customer_state,
    c.customer_city,
    date_trunc('month', o.order_purchase_timestamp)::date AS sales_month,
    COUNT(DISTINCT o.order_id) AS orders_count,
    COALESCE(SUM(op.payment_value), 0) AS total_payment_value
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
LEFT JOIN order_payments op ON op.order_id = o.order_id
GROUP BY 1, 2, 3
WITH NO DATA;

CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_geo_sales_summary
    ON mv_geo_sales_summary (customer_state, customer_city, sales_month);

