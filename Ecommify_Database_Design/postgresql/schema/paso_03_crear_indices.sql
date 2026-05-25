-- Ecommify Database Design
-- Paso 03: crear indices iniciales.
-- Los indices se alinean con accesos OLTP y necesidades de refresco analitico.

SET search_path TO ecommify, public;

CREATE INDEX IF NOT EXISTS idx_customers_unique_id
    ON customers (customer_unique_id);

CREATE INDEX IF NOT EXISTS idx_customers_zip_state
    ON customers (customer_zip_code_prefix, customer_state);

CREATE INDEX IF NOT EXISTS idx_sellers_zip_state
    ON sellers (seller_zip_code_prefix, seller_state);

CREATE INDEX IF NOT EXISTS idx_products_category
    ON products (product_category_name);

CREATE INDEX IF NOT EXISTS idx_products_specifications_gin
    ON products USING GIN (specifications);

CREATE INDEX IF NOT EXISTS idx_products_photo_urls_gin
    ON products USING GIN (photo_urls);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id
    ON orders (customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_purchase_timestamp
    ON orders (order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_orders_status_purchase_timestamp
    ON orders (order_status, order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_orders_lifecycle_gin
    ON orders USING GIN (lifecycle);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id
    ON order_items (product_id);

CREATE INDEX IF NOT EXISTS idx_order_items_seller_id
    ON order_items (seller_id);

CREATE INDEX IF NOT EXISTS idx_order_payments_type
    ON order_payments (payment_type);

CREATE INDEX IF NOT EXISTS idx_order_reviews_order_id
    ON order_reviews (order_id);

CREATE INDEX IF NOT EXISTS idx_order_reviews_score
    ON order_reviews (review_score);

CREATE INDEX IF NOT EXISTS idx_geolocation_clean_zip_state
    ON geolocation_clean (geolocation_zip_code_prefix, geolocation_state);

