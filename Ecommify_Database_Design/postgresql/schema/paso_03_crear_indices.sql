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

-- Indice espacial con PostGIS.
-- geog es una columna generada desde latitud/longitud limpias en geolocation_clean.
CREATE INDEX IF NOT EXISTS idx_geolocation_clean_geog_gist
    ON geolocation_clean USING GIST (geog)
    WHERE geog IS NOT NULL;

-- Indices de similitud textual con pg_trgm.
-- Requieren que el paso 01 haya habilitado la extension pg_trgm.
-- No cambian el modelo ER; optimizan busquedas aproximadas y tolerantes a errores.
CREATE INDEX IF NOT EXISTS idx_customers_city_trgm
    ON customers USING GIN (customer_city gin_trgm_ops)
    WHERE customer_city IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_sellers_city_trgm
    ON sellers USING GIN (seller_city gin_trgm_ops)
    WHERE seller_city IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_category_name_trgm
    ON category_translation USING GIN (product_category_name gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_category_name_english_trgm
    ON category_translation USING GIN (product_category_name_english gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_order_reviews_title_trgm
    ON order_reviews USING GIN (review_comment_title gin_trgm_ops)
    WHERE review_comment_title IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_order_reviews_message_trgm
    ON order_reviews USING GIN (review_comment_message gin_trgm_ops)
    WHERE review_comment_message IS NOT NULL;
