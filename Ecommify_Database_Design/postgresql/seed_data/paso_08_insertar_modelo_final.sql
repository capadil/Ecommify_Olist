-- Ecommify Database Design
-- Paso 08: insertar datos desde staging hacia el modelo final normalizado.
-- Resuelve llaves tecnicas internas y conserva IDs Olist como TEXT UNIQUE.

SET search_path TO ecommify, public;

BEGIN;

INSERT INTO category_translation (product_category_name, product_category_name_english)
SELECT DISTINCT product_category_name, product_category_name_english
FROM stg_category_translation
WHERE product_category_name IS NOT NULL
ON CONFLICT (product_category_name) DO UPDATE
SET product_category_name_english = EXCLUDED.product_category_name_english;

INSERT INTO customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
SELECT DISTINCT ON (customer_id)
    customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state
FROM stg_customers
WHERE customer_id IS NOT NULL
ORDER BY customer_id
ON CONFLICT (customer_id) DO UPDATE
SET customer_unique_id = EXCLUDED.customer_unique_id,
    customer_zip_code_prefix = EXCLUDED.customer_zip_code_prefix,
    customer_city = EXCLUDED.customer_city,
    customer_state = EXCLUDED.customer_state;

INSERT INTO sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state)
SELECT DISTINCT ON (seller_id)
    seller_id, seller_zip_code_prefix, seller_city, seller_state
FROM stg_sellers
WHERE seller_id IS NOT NULL
ORDER BY seller_id
ON CONFLICT (seller_id) DO UPDATE
SET seller_zip_code_prefix = EXCLUDED.seller_zip_code_prefix,
    seller_city = EXCLUDED.seller_city,
    seller_state = EXCLUDED.seller_state;

INSERT INTO products (
    product_id, category_sk, product_name_lenght, product_description_lenght,
    product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm
)
SELECT DISTINCT ON (p.product_id)
    p.product_id, ct.category_sk, p.product_name_lenght, p.product_description_lenght,
    p.product_photos_qty, p.product_weight_g, p.product_length_cm, p.product_height_cm, p.product_width_cm
FROM stg_products p
LEFT JOIN category_translation ct ON ct.product_category_name = p.product_category_name
WHERE p.product_id IS NOT NULL
ORDER BY p.product_id
ON CONFLICT (product_id) DO UPDATE
SET category_sk = EXCLUDED.category_sk,
    product_name_lenght = EXCLUDED.product_name_lenght,
    product_description_lenght = EXCLUDED.product_description_lenght,
    product_photos_qty = EXCLUDED.product_photos_qty,
    product_weight_g = EXCLUDED.product_weight_g,
    product_length_cm = EXCLUDED.product_length_cm,
    product_height_cm = EXCLUDED.product_height_cm,
    product_width_cm = EXCLUDED.product_width_cm;

INSERT INTO orders (
    order_id, customer_sk, order_status, order_purchase_timestamp, order_approved_at,
    order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date
)
SELECT DISTINCT ON (o.order_id)
    o.order_id, c.customer_sk, o.order_status, o.order_purchase_timestamp, o.order_approved_at,
    o.order_delivered_carrier_date, o.order_delivered_customer_date, o.order_estimated_delivery_date
FROM stg_orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_id IS NOT NULL
ORDER BY o.order_id
ON CONFLICT (order_id) DO UPDATE
SET customer_sk = EXCLUDED.customer_sk,
    order_status = EXCLUDED.order_status,
    order_purchase_timestamp = EXCLUDED.order_purchase_timestamp,
    order_approved_at = EXCLUDED.order_approved_at,
    order_delivered_carrier_date = EXCLUDED.order_delivered_carrier_date,
    order_delivered_customer_date = EXCLUDED.order_delivered_customer_date,
    order_estimated_delivery_date = EXCLUDED.order_estimated_delivery_date;

INSERT INTO order_items (order_sk, order_item_id, product_sk, seller_sk, shipping_limit_date, price, freight_value)
SELECT o.order_sk, oi.order_item_id, p.product_sk, s.seller_sk, oi.shipping_limit_date, oi.price, oi.freight_value
FROM stg_order_items oi
JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN products p ON p.product_id = oi.product_id
LEFT JOIN sellers s ON s.seller_id = oi.seller_id
WHERE oi.order_id IS NOT NULL AND oi.order_item_id IS NOT NULL
ON CONFLICT (order_sk, order_item_id) DO UPDATE
SET product_sk = EXCLUDED.product_sk,
    seller_sk = EXCLUDED.seller_sk,
    shipping_limit_date = EXCLUDED.shipping_limit_date,
    price = EXCLUDED.price,
    freight_value = EXCLUDED.freight_value;

INSERT INTO order_payments (order_sk, payment_sequential, payment_type, payment_installments, payment_value)
SELECT o.order_sk, op.payment_sequential, op.payment_type, op.payment_installments, op.payment_value
FROM stg_order_payments op
JOIN orders o ON o.order_id = op.order_id
WHERE op.order_id IS NOT NULL AND op.payment_sequential IS NOT NULL
ON CONFLICT (order_sk, payment_sequential) DO UPDATE
SET payment_type = EXCLUDED.payment_type,
    payment_installments = EXCLUDED.payment_installments,
    payment_value = EXCLUDED.payment_value;

INSERT INTO order_reviews (
    review_id, order_sk, review_score, review_comment_title, review_comment_message,
    review_creation_date, review_answer_timestamp
)
SELECT DISTINCT ON (r.review_id, o.order_sk)
    r.review_id, o.order_sk, r.review_score, r.review_comment_title, r.review_comment_message,
    r.review_creation_date, r.review_answer_timestamp
FROM stg_order_reviews r
JOIN orders o ON o.order_id = r.order_id
WHERE r.review_id IS NOT NULL
ORDER BY r.review_id, o.order_sk
ON CONFLICT (review_id, order_sk) DO UPDATE
SET review_score = EXCLUDED.review_score,
    review_comment_title = EXCLUDED.review_comment_title,
    review_comment_message = EXCLUDED.review_comment_message,
    review_creation_date = EXCLUDED.review_creation_date,
    review_answer_timestamp = EXCLUDED.review_answer_timestamp;

TRUNCATE TABLE geolocation_clean RESTART IDENTITY;
INSERT INTO geolocation_clean (
    geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state
)
SELECT
    geolocation_zip_code_prefix,
    AVG(geolocation_lat)::NUMERIC(10, 7),
    AVG(geolocation_lng)::NUMERIC(10, 7),
    geolocation_city,
    geolocation_state
FROM stg_geolocation
WHERE geolocation_zip_code_prefix IS NOT NULL
GROUP BY geolocation_zip_code_prefix, geolocation_city, geolocation_state;

COMMIT;