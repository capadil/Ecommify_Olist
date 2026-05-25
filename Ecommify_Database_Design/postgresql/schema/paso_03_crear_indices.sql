-- Ecommify Database Design
-- Paso 03: crear indices iniciales.
-- Objetivo: soportar consultas OLTP por claves internas y busquedas por identificadores Olist.

SET search_path TO ecommify, public;

-- Identificadores externos Olist para trazabilidad y busqueda operacional.
CREATE INDEX IF NOT EXISTS idx_customers_customer_id
    ON customers (customer_id);

CREATE INDEX IF NOT EXISTS idx_customers_unique_id
    ON customers (customer_unique_id);

CREATE INDEX IF NOT EXISTS idx_sellers_seller_id
    ON sellers (seller_id);

CREATE INDEX IF NOT EXISTS idx_products_product_id
    ON products (product_id);

CREATE INDEX IF NOT EXISTS idx_orders_order_id
    ON orders (order_id);

CREATE INDEX IF NOT EXISTS idx_order_reviews_review_id
    ON order_reviews (review_id);

-- Llaves foraneas internas para joins relacionales eficientes.
CREATE INDEX IF NOT EXISTS idx_products_category_sk
    ON products (category_sk);

CREATE INDEX IF NOT EXISTS idx_orders_customer_sk
    ON orders (customer_sk);

CREATE INDEX IF NOT EXISTS idx_order_items_order_sk
    ON order_items (order_sk);

CREATE INDEX IF NOT EXISTS idx_order_items_product_sk
    ON order_items (product_sk);

CREATE INDEX IF NOT EXISTS idx_order_items_seller_sk
    ON order_items (seller_sk);

CREATE INDEX IF NOT EXISTS idx_order_payments_order_sk
    ON order_payments (order_sk);

CREATE INDEX IF NOT EXISTS idx_order_reviews_order_sk
    ON order_reviews (order_sk);

-- Indices de consulta y analitica.
CREATE INDEX IF NOT EXISTS idx_customers_zip_state
    ON customers (customer_zip_code_prefix, customer_state);

CREATE INDEX IF NOT EXISTS idx_sellers_zip_state
    ON sellers (seller_zip_code_prefix, seller_state);

CREATE INDEX IF NOT EXISTS idx_products_specifications_gin
    ON products USING GIN (specifications);

CREATE INDEX IF NOT EXISTS idx_products_photo_urls_gin
    ON products USING GIN (photo_urls);

CREATE INDEX IF NOT EXISTS idx_orders_purchase_timestamp
    ON orders (order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_orders_status_purchase_timestamp
    ON orders (order_status, order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_orders_lifecycle_gin
    ON orders USING GIN (lifecycle);

CREATE INDEX IF NOT EXISTS idx_order_payments_type
    ON order_payments (payment_type);

CREATE INDEX IF NOT EXISTS idx_order_reviews_score
    ON order_reviews (review_score);

CREATE INDEX IF NOT EXISTS idx_geolocation_clean_zip_state
    ON geolocation_clean (geolocation_zip_code_prefix, geolocation_state);
