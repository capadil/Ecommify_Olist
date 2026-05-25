-- Ecommify Database Design
-- Paso 02: crear tablas base normalizadas en PostgreSQL.
-- Decision: PostgreSQL conserva el nucleo transaccional del proyecto.
-- Decision: los IDs originales de Olist se mantienen como TEXT UNIQUE para trazabilidad.
-- Decision: las PK relacionales usan llaves tecnicas BIGINT GENERATED ALWAYS AS IDENTITY.
-- Decision: JSONB y arrays se usan solo como tipos avanzados controlados, sin reemplazar relaciones transaccionales.

SET search_path TO ecommify, public;

BEGIN;

CREATE TABLE IF NOT EXISTS category_translation (
    category_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_category_name TEXT NOT NULL UNIQUE,
    product_category_name_english TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS customers (
    customer_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id TEXT NOT NULL UNIQUE,
    customer_unique_id TEXT NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state CHAR(2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sellers (
    seller_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seller_id TEXT NOT NULL UNIQUE,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state CHAR(2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS products (
    product_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id TEXT NOT NULL UNIQUE,
    category_sk BIGINT REFERENCES category_translation(category_sk)
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
    order_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id TEXT NOT NULL UNIQUE,
    customer_sk BIGINT NOT NULL REFERENCES customers(customer_sk)
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
    order_item_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_sk BIGINT NOT NULL REFERENCES orders(order_sk)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    order_item_id INTEGER NOT NULL,
    product_sk BIGINT REFERENCES products(product_sk)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    seller_sk BIGINT REFERENCES sellers(seller_sk)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    freight_value NUMERIC(12, 2) NOT NULL CHECK (freight_value >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_order_items_order_line UNIQUE (order_sk, order_item_id)
);

CREATE TABLE IF NOT EXISTS order_payments (
    payment_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_sk BIGINT NOT NULL REFERENCES orders(order_sk)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    payment_sequential INTEGER NOT NULL,
    payment_type TEXT NOT NULL,
    payment_installments INTEGER CHECK (payment_installments IS NULL OR payment_installments >= 0),
    payment_value NUMERIC(12, 2) NOT NULL CHECK (payment_value >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_order_payments_order_sequence UNIQUE (order_sk, payment_sequential)
);

CREATE TABLE IF NOT EXISTS order_reviews (
    review_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    review_id TEXT NOT NULL,
    order_sk BIGINT NOT NULL REFERENCES orders(order_sk)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    review_score INTEGER NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_order_reviews_source UNIQUE (review_id, order_sk)
);

CREATE TABLE IF NOT EXISTS geolocation_clean (
    geolocation_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    geolocation_zip_code_prefix INTEGER NOT NULL,
    geolocation_lat NUMERIC(10, 7),
    geolocation_lng NUMERIC(10, 7),
    geolocation_city TEXT,
    geolocation_state CHAR(2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMIT;
