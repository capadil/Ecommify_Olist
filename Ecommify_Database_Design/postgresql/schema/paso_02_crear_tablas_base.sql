-- Ecommify Database Design
-- Paso 02: crear tablas base normalizadas en PostgreSQL.
-- Fuente de verdad: PostgreSQL.
-- Los IDs de Olist se preservan como TEXT. uuid-ossp no se usa en el diseno inicial.

SET search_path TO ecommify, public;

BEGIN;

CREATE TABLE IF NOT EXISTS category_translation (
    product_category_name TEXT PRIMARY KEY,
    product_category_name_english TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS customers (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state CHAR(2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sellers (
    seller_id TEXT PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state CHAR(2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS products (
    product_id TEXT PRIMARY KEY,
    product_category_name TEXT REFERENCES category_translation(product_category_name)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    product_name_lenght INTEGER CHECK (product_name_lenght IS NULL OR product_name_lenght >= 0),
    product_description_lenght INTEGER CHECK (product_description_lenght IS NULL OR product_description_lenght >= 0),
    product_photos_qty INTEGER CHECK (product_photos_qty IS NULL OR product_photos_qty >= 0),
    product_weight_g INTEGER CHECK (product_weight_g IS NULL OR product_weight_g >= 0),
    product_length_cm INTEGER CHECK (product_length_cm IS NULL OR product_length_cm >= 0),
    product_height_cm INTEGER CHECK (product_height_cm IS NULL OR product_height_cm >= 0),
    product_width_cm INTEGER CHECK (product_width_cm IS NULL OR product_width_cm >= 0),
    specifications JSONB NOT NULL DEFAULT '{}'::jsonb,
    photo_urls TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT products_specifications_is_object CHECK (jsonb_typeof(specifications) = 'object')
);

CREATE TABLE IF NOT EXISTS orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    order_status TEXT NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    lifecycle JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT orders_lifecycle_is_array_or_object CHECK (jsonb_typeof(lifecycle) IN ('array', 'object'))
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id TEXT NOT NULL REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    order_item_id INTEGER NOT NULL,
    product_id TEXT REFERENCES products(product_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    seller_id TEXT REFERENCES sellers(seller_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    freight_value NUMERIC(12, 2) NOT NULL CHECK (freight_value >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE IF NOT EXISTS order_payments (
    order_id TEXT NOT NULL REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    payment_sequential INTEGER NOT NULL,
    payment_type TEXT NOT NULL,
    payment_installments INTEGER CHECK (payment_installments IS NULL OR payment_installments >= 0),
    payment_value NUMERIC(12, 2) NOT NULL CHECK (payment_value >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE IF NOT EXISTS order_reviews (
    review_id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL UNIQUE REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    review_score INTEGER NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS geolocation_clean (
    geolocation_id BIGSERIAL PRIMARY KEY,
    geolocation_zip_code_prefix INTEGER NOT NULL,
    geolocation_lat NUMERIC(10, 7),
    geolocation_lng NUMERIC(10, 7),
    geolocation_city TEXT,
    geolocation_state CHAR(2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMIT;

