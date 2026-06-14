--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4 (Debian 16.4-1.pgdg110+2)
-- Dumped by pg_dump version 16.4 (Debian 16.4-1.pgdg110+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: ecommify; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA ecommify;


--
-- Name: SCHEMA ecommify; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA ecommify IS 'Fuente de verdad transaccional de Ecommify. MongoDB consume documentos analiticos derivados.';


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: ecommify; Owner: -
--

CREATE FUNCTION ecommify.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: category_translation; Type: TABLE; Schema: ecommify; Owner: -
--

CREATE TABLE ecommify.category_translation (
    category_sk bigint NOT NULL,
    product_category_name text NOT NULL,
    product_category_name_english text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: category_translation_category_sk_seq; Type: SEQUENCE; Schema: ecommify; Owner: -
--

ALTER TABLE ecommify.category_translation ALTER COLUMN category_sk ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ecommify.category_translation_category_sk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: customers; Type: TABLE; Schema: ecommify; Owner: -
--

CREATE TABLE ecommify.customers (
    customer_sk bigint NOT NULL,
    customer_id text NOT NULL,
    customer_unique_id text NOT NULL,
    customer_zip_code_prefix integer,
    customer_city text,
    customer_state character(2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: customers_customer_sk_seq; Type: SEQUENCE; Schema: ecommify; Owner: -
--

ALTER TABLE ecommify.customers ALTER COLUMN customer_sk ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ecommify.customers_customer_sk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: geolocation_clean; Type: TABLE; Schema: ecommify; Owner: -
--

CREATE TABLE ecommify.geolocation_clean (
    geolocation_sk bigint NOT NULL,
    geolocation_zip_code_prefix integer NOT NULL,
    geolocation_lat numeric(10,7),
    geolocation_lng numeric(10,7),
    geog public.geography(Point,4326) GENERATED ALWAYS AS (
CASE
    WHEN ((geolocation_lat IS NOT NULL) AND (geolocation_lng IS NOT NULL)) THEN (public.st_setsrid(public.st_makepoint((geolocation_lng)::double precision, (geolocation_lat)::double precision), 4326))::public.geography
    ELSE NULL::public.geography
END) STORED,
    geolocation_city text,
    geolocation_state character(2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: geolocation_clean_geolocation_sk_seq; Type: SEQUENCE; Schema: ecommify; Owner: -
--

ALTER TABLE ecommify.geolocation_clean ALTER COLUMN geolocation_sk ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ecommify.geolocation_clean_geolocation_sk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: order_payments; Type: TABLE; Schema: ecommify; Owner: -
--

CREATE TABLE ecommify.order_payments (
    payment_sk bigint NOT NULL,
    order_sk bigint NOT NULL,
    payment_sequential integer NOT NULL,
    payment_type text NOT NULL,
    payment_installments integer,
    payment_value numeric(12,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT order_payments_payment_installments_check CHECK (((payment_installments IS NULL) OR (payment_installments >= 0))),
    CONSTRAINT order_payments_payment_value_check CHECK ((payment_value >= (0)::numeric))
);


--
-- Name: order_reviews; Type: TABLE; Schema: ecommify; Owner: -
--

CREATE TABLE ecommify.order_reviews (
    review_sk bigint NOT NULL,
    review_id text NOT NULL,
    order_sk bigint NOT NULL,
    review_score integer NOT NULL,
    review_comment_title text,
    review_comment_message text,
    review_creation_date timestamp without time zone,
    review_answer_timestamp timestamp without time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT order_reviews_review_score_check CHECK (((review_score >= 1) AND (review_score <= 5)))
);


--
-- Name: orders; Type: TABLE; Schema: ecommify; Owner: -
--

CREATE TABLE ecommify.orders (
    order_sk bigint NOT NULL,
    order_id text NOT NULL,
    customer_sk bigint NOT NULL,
    order_status text NOT NULL,
    order_purchase_timestamp timestamp without time zone NOT NULL,
    order_approved_at timestamp without time zone,
    order_delivered_carrier_date timestamp without time zone,
    order_delivered_customer_date timestamp without time zone,
    order_estimated_delivery_date timestamp without time zone,
    lifecycle jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT orders_lifecycle_is_array_or_object CHECK ((jsonb_typeof(lifecycle) = ANY (ARRAY['array'::text, 'object'::text])))
);


--
-- Name: mv_customer_segments; Type: MATERIALIZED VIEW; Schema: ecommify; Owner: -
--

CREATE MATERIALIZED VIEW ecommify.mv_customer_segments AS
 SELECT c.customer_sk,
    c.customer_id,
    c.customer_unique_id,
    c.customer_state,
    count(DISTINCT o.order_sk) AS orders_count,
    COALESCE(sum(op.payment_value), (0)::numeric) AS total_payment_value,
    min(o.order_purchase_timestamp) AS first_order_at,
    max(o.order_purchase_timestamp) AS last_order_at,
    avg(r.review_score) AS avg_review_score,
        CASE
            WHEN (COALESCE(sum(op.payment_value), (0)::numeric) >= (1000)::numeric) THEN 'high_value'::text
            WHEN (count(DISTINCT o.order_sk) >= 3) THEN 'repeat_customer'::text
            ELSE 'standard'::text
        END AS customer_segment
   FROM (((ecommify.customers c
     LEFT JOIN ecommify.orders o ON ((o.customer_sk = c.customer_sk)))
     LEFT JOIN ecommify.order_payments op ON ((op.order_sk = o.order_sk)))
     LEFT JOIN ecommify.order_reviews r ON ((r.order_sk = o.order_sk)))
  GROUP BY c.customer_sk, c.customer_id, c.customer_unique_id, c.customer_state
  WITH NO DATA;


--
-- Name: mv_geo_sales_summary; Type: MATERIALIZED VIEW; Schema: ecommify; Owner: -
--

CREATE MATERIALIZED VIEW ecommify.mv_geo_sales_summary AS
 SELECT c.customer_state,
    c.customer_city,
    (date_trunc('month'::text, o.order_purchase_timestamp))::date AS sales_month,
    count(DISTINCT o.order_sk) AS orders_count,
    COALESCE(sum(op.payment_value), (0)::numeric) AS total_payment_value
   FROM ((ecommify.customers c
     JOIN ecommify.orders o ON ((o.customer_sk = c.customer_sk)))
     LEFT JOIN ecommify.order_payments op ON ((op.order_sk = o.order_sk)))
  GROUP BY c.customer_state, c.customer_city, ((date_trunc('month'::text, o.order_purchase_timestamp))::date)
  WITH NO DATA;


--
-- Name: order_items; Type: TABLE; Schema: ecommify; Owner: -
--

CREATE TABLE ecommify.order_items (
    order_item_sk bigint NOT NULL,
    order_sk bigint NOT NULL,
    order_item_id integer NOT NULL,
    product_sk bigint,
    seller_sk bigint,
    shipping_limit_date timestamp without time zone,
    price numeric(12,2) NOT NULL,
    freight_value numeric(12,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT order_items_freight_value_check CHECK ((freight_value >= (0)::numeric)),
    CONSTRAINT order_items_price_check CHECK ((price >= (0)::numeric))
);


--
-- Name: products; Type: TABLE; Schema: ecommify; Owner: -
--

CREATE TABLE ecommify.products (
    product_sk bigint NOT NULL,
    product_id text NOT NULL,
    category_sk bigint,
    product_name_lenght integer,
    product_description_lenght integer,
    product_photos_qty integer,
    product_weight_g integer,
    product_length_cm integer,
    product_height_cm integer,
    product_width_cm integer,
    specifications jsonb DEFAULT '{}'::jsonb NOT NULL,
    photo_urls text[] DEFAULT ARRAY[]::text[] NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT products_product_description_lenght_check CHECK (((product_description_lenght IS NULL) OR (product_description_lenght >= 0))),
    CONSTRAINT products_product_height_cm_check CHECK (((product_height_cm IS NULL) OR (product_height_cm >= 0))),
    CONSTRAINT products_product_length_cm_check CHECK (((product_length_cm IS NULL) OR (product_length_cm >= 0))),
    CONSTRAINT products_product_name_lenght_check CHECK (((product_name_lenght IS NULL) OR (product_name_lenght >= 0))),
    CONSTRAINT products_product_photos_qty_check CHECK (((product_photos_qty IS NULL) OR (product_photos_qty >= 0))),
    CONSTRAINT products_product_weight_g_check CHECK (((product_weight_g IS NULL) OR (product_weight_g >= 0))),
    CONSTRAINT products_product_width_cm_check CHECK (((product_width_cm IS NULL) OR (product_width_cm >= 0))),
    CONSTRAINT products_specifications_is_object CHECK ((jsonb_typeof(specifications) = 'object'::text))
);


--
-- Name: mv_sales_by_category_monthly; Type: MATERIALIZED VIEW; Schema: ecommify; Owner: -
--

CREATE MATERIALIZED VIEW ecommify.mv_sales_by_category_monthly AS
 SELECT (date_trunc('month'::text, o.order_purchase_timestamp))::date AS sales_month,
    COALESCE(ct.product_category_name_english, ct.product_category_name, 'unknown'::text) AS category_name,
    count(DISTINCT o.order_sk) AS orders_count,
    count(*) AS items_count,
    sum(oi.price) AS gross_sales,
    sum(oi.freight_value) AS freight_total,
    sum((oi.price + oi.freight_value)) AS total_value
   FROM (((ecommify.orders o
     JOIN ecommify.order_items oi ON ((oi.order_sk = o.order_sk)))
     LEFT JOIN ecommify.products p ON ((p.product_sk = oi.product_sk)))
     LEFT JOIN ecommify.category_translation ct ON ((ct.category_sk = p.category_sk)))
  GROUP BY ((date_trunc('month'::text, o.order_purchase_timestamp))::date), COALESCE(ct.product_category_name_english, ct.product_category_name, 'unknown'::text)
  WITH NO DATA;


--
-- Name: sellers; Type: TABLE; Schema: ecommify; Owner: -
--

CREATE TABLE ecommify.sellers (
    seller_sk bigint NOT NULL,
    seller_id text NOT NULL,
    seller_zip_code_prefix integer,
    seller_city text,
    seller_state character(2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: mv_seller_performance_monthly; Type: MATERIALIZED VIEW; Schema: ecommify; Owner: -
--

CREATE MATERIALIZED VIEW ecommify.mv_seller_performance_monthly AS
 SELECT (date_trunc('month'::text, o.order_purchase_timestamp))::date AS sales_month,
    s.seller_sk,
    s.seller_id,
    s.seller_state,
    count(DISTINCT o.order_sk) AS orders_count,
    count(*) AS items_count,
    sum(oi.price) AS gross_sales,
    avg(r.review_score) AS avg_review_score
   FROM (((ecommify.sellers s
     JOIN ecommify.order_items oi ON ((oi.seller_sk = s.seller_sk)))
     JOIN ecommify.orders o ON ((o.order_sk = oi.order_sk)))
     LEFT JOIN ecommify.order_reviews r ON ((r.order_sk = o.order_sk)))
  GROUP BY ((date_trunc('month'::text, o.order_purchase_timestamp))::date), s.seller_sk, s.seller_id, s.seller_state
  WITH NO DATA;


--
-- Name: order_items_order_item_sk_seq; Type: SEQUENCE; Schema: ecommify; Owner: -
--

ALTER TABLE ecommify.order_items ALTER COLUMN order_item_sk ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ecommify.order_items_order_item_sk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: order_payments_payment_sk_seq; Type: SEQUENCE; Schema: ecommify; Owner: -
--

ALTER TABLE ecommify.order_payments ALTER COLUMN payment_sk ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ecommify.order_payments_payment_sk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: order_reviews_review_sk_seq; Type: SEQUENCE; Schema: ecommify; Owner: -
--

ALTER TABLE ecommify.order_reviews ALTER COLUMN review_sk ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ecommify.order_reviews_review_sk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: orders_order_sk_seq; Type: SEQUENCE; Schema: ecommify; Owner: -
--

ALTER TABLE ecommify.orders ALTER COLUMN order_sk ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ecommify.orders_order_sk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: products_product_sk_seq; Type: SEQUENCE; Schema: ecommify; Owner: -
--

ALTER TABLE ecommify.products ALTER COLUMN product_sk ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ecommify.products_product_sk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sellers_seller_sk_seq; Type: SEQUENCE; Schema: ecommify; Owner: -
--

ALTER TABLE ecommify.sellers ALTER COLUMN seller_sk ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME ecommify.sellers_seller_sk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: category_translation category_translation_pkey; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.category_translation
    ADD CONSTRAINT category_translation_pkey PRIMARY KEY (category_sk);


--
-- Name: category_translation category_translation_product_category_name_key; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.category_translation
    ADD CONSTRAINT category_translation_product_category_name_key UNIQUE (product_category_name);


--
-- Name: customers customers_customer_id_key; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.customers
    ADD CONSTRAINT customers_customer_id_key UNIQUE (customer_id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_sk);


--
-- Name: geolocation_clean geolocation_clean_pkey; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.geolocation_clean
    ADD CONSTRAINT geolocation_clean_pkey PRIMARY KEY (geolocation_sk);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (order_item_sk);


--
-- Name: order_payments order_payments_pkey; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.order_payments
    ADD CONSTRAINT order_payments_pkey PRIMARY KEY (payment_sk);


--
-- Name: order_reviews order_reviews_pkey; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.order_reviews
    ADD CONSTRAINT order_reviews_pkey PRIMARY KEY (review_sk);


--
-- Name: orders orders_order_id_key; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.orders
    ADD CONSTRAINT orders_order_id_key UNIQUE (order_id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_sk);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_sk);


--
-- Name: products products_product_id_key; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.products
    ADD CONSTRAINT products_product_id_key UNIQUE (product_id);


--
-- Name: sellers sellers_pkey; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.sellers
    ADD CONSTRAINT sellers_pkey PRIMARY KEY (seller_sk);


--
-- Name: sellers sellers_seller_id_key; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.sellers
    ADD CONSTRAINT sellers_seller_id_key UNIQUE (seller_id);


--
-- Name: order_items uq_order_items_order_line; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.order_items
    ADD CONSTRAINT uq_order_items_order_line UNIQUE (order_sk, order_item_id);


--
-- Name: order_payments uq_order_payments_order_sequence; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.order_payments
    ADD CONSTRAINT uq_order_payments_order_sequence UNIQUE (order_sk, payment_sequential);


--
-- Name: order_reviews uq_order_reviews_source; Type: CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.order_reviews
    ADD CONSTRAINT uq_order_reviews_source UNIQUE (review_id, order_sk);


--
-- Name: idx_category_name_english_trgm; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_category_name_english_trgm ON ecommify.category_translation USING gin (product_category_name_english public.gin_trgm_ops);


--
-- Name: idx_category_name_trgm; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_category_name_trgm ON ecommify.category_translation USING gin (product_category_name public.gin_trgm_ops);


--
-- Name: idx_customers_city_trgm; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_customers_city_trgm ON ecommify.customers USING gin (customer_city public.gin_trgm_ops) WHERE (customer_city IS NOT NULL);


--
-- Name: idx_customers_customer_id; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_customers_customer_id ON ecommify.customers USING btree (customer_id);


--
-- Name: idx_customers_unique_id; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_customers_unique_id ON ecommify.customers USING btree (customer_unique_id);


--
-- Name: idx_customers_zip_state; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_customers_zip_state ON ecommify.customers USING btree (customer_zip_code_prefix, customer_state);


--
-- Name: idx_geolocation_clean_geog_gist; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_geolocation_clean_geog_gist ON ecommify.geolocation_clean USING gist (geog) WHERE (geog IS NOT NULL);


--
-- Name: idx_geolocation_clean_zip_state; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_geolocation_clean_zip_state ON ecommify.geolocation_clean USING btree (geolocation_zip_code_prefix, geolocation_state);


--
-- Name: idx_order_items_order_sk; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_order_items_order_sk ON ecommify.order_items USING btree (order_sk);


--
-- Name: idx_order_items_product_sk; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_order_items_product_sk ON ecommify.order_items USING btree (product_sk);


--
-- Name: idx_order_items_seller_sk; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_order_items_seller_sk ON ecommify.order_items USING btree (seller_sk);


--
-- Name: idx_order_payments_order_sk; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_order_payments_order_sk ON ecommify.order_payments USING btree (order_sk);


--
-- Name: idx_order_payments_type; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_order_payments_type ON ecommify.order_payments USING btree (payment_type);


--
-- Name: idx_order_reviews_message_trgm; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_order_reviews_message_trgm ON ecommify.order_reviews USING gin (review_comment_message public.gin_trgm_ops) WHERE (review_comment_message IS NOT NULL);


--
-- Name: idx_order_reviews_order_sk; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_order_reviews_order_sk ON ecommify.order_reviews USING btree (order_sk);


--
-- Name: idx_order_reviews_review_id; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_order_reviews_review_id ON ecommify.order_reviews USING btree (review_id);


--
-- Name: idx_order_reviews_score; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_order_reviews_score ON ecommify.order_reviews USING btree (review_score);


--
-- Name: idx_order_reviews_title_trgm; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_order_reviews_title_trgm ON ecommify.order_reviews USING gin (review_comment_title public.gin_trgm_ops) WHERE (review_comment_title IS NOT NULL);


--
-- Name: idx_orders_customer_sk; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_orders_customer_sk ON ecommify.orders USING btree (customer_sk);


--
-- Name: idx_orders_lifecycle_gin; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_orders_lifecycle_gin ON ecommify.orders USING gin (lifecycle);


--
-- Name: idx_orders_order_id; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_orders_order_id ON ecommify.orders USING btree (order_id);


--
-- Name: idx_orders_purchase_timestamp; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_orders_purchase_timestamp ON ecommify.orders USING btree (order_purchase_timestamp);


--
-- Name: idx_orders_status_purchase_timestamp; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_orders_status_purchase_timestamp ON ecommify.orders USING btree (order_status, order_purchase_timestamp);


--
-- Name: idx_products_category_sk; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_products_category_sk ON ecommify.products USING btree (category_sk);


--
-- Name: idx_products_photo_urls_gin; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_products_photo_urls_gin ON ecommify.products USING gin (photo_urls);


--
-- Name: idx_products_product_id; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_products_product_id ON ecommify.products USING btree (product_id);


--
-- Name: idx_products_specifications_gin; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_products_specifications_gin ON ecommify.products USING gin (specifications);


--
-- Name: idx_sellers_city_trgm; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_sellers_city_trgm ON ecommify.sellers USING gin (seller_city public.gin_trgm_ops) WHERE (seller_city IS NOT NULL);


--
-- Name: idx_sellers_seller_id; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_sellers_seller_id ON ecommify.sellers USING btree (seller_id);


--
-- Name: idx_sellers_zip_state; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE INDEX idx_sellers_zip_state ON ecommify.sellers USING btree (seller_zip_code_prefix, seller_state);


--
-- Name: ux_mv_customer_segments; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE UNIQUE INDEX ux_mv_customer_segments ON ecommify.mv_customer_segments USING btree (customer_sk);


--
-- Name: ux_mv_geo_sales_summary; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE UNIQUE INDEX ux_mv_geo_sales_summary ON ecommify.mv_geo_sales_summary USING btree (customer_state, customer_city, sales_month);


--
-- Name: ux_mv_sales_by_category_monthly; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE UNIQUE INDEX ux_mv_sales_by_category_monthly ON ecommify.mv_sales_by_category_monthly USING btree (sales_month, category_name);


--
-- Name: ux_mv_seller_performance_monthly; Type: INDEX; Schema: ecommify; Owner: -
--

CREATE UNIQUE INDEX ux_mv_seller_performance_monthly ON ecommify.mv_seller_performance_monthly USING btree (sales_month, seller_sk);


--
-- Name: category_translation trg_category_translation_updated_at; Type: TRIGGER; Schema: ecommify; Owner: -
--

CREATE TRIGGER trg_category_translation_updated_at BEFORE UPDATE ON ecommify.category_translation FOR EACH ROW EXECUTE FUNCTION ecommify.set_updated_at();


--
-- Name: customers trg_customers_updated_at; Type: TRIGGER; Schema: ecommify; Owner: -
--

CREATE TRIGGER trg_customers_updated_at BEFORE UPDATE ON ecommify.customers FOR EACH ROW EXECUTE FUNCTION ecommify.set_updated_at();


--
-- Name: geolocation_clean trg_geolocation_clean_updated_at; Type: TRIGGER; Schema: ecommify; Owner: -
--

CREATE TRIGGER trg_geolocation_clean_updated_at BEFORE UPDATE ON ecommify.geolocation_clean FOR EACH ROW EXECUTE FUNCTION ecommify.set_updated_at();


--
-- Name: order_items trg_order_items_updated_at; Type: TRIGGER; Schema: ecommify; Owner: -
--

CREATE TRIGGER trg_order_items_updated_at BEFORE UPDATE ON ecommify.order_items FOR EACH ROW EXECUTE FUNCTION ecommify.set_updated_at();


--
-- Name: order_payments trg_order_payments_updated_at; Type: TRIGGER; Schema: ecommify; Owner: -
--

CREATE TRIGGER trg_order_payments_updated_at BEFORE UPDATE ON ecommify.order_payments FOR EACH ROW EXECUTE FUNCTION ecommify.set_updated_at();


--
-- Name: order_reviews trg_order_reviews_updated_at; Type: TRIGGER; Schema: ecommify; Owner: -
--

CREATE TRIGGER trg_order_reviews_updated_at BEFORE UPDATE ON ecommify.order_reviews FOR EACH ROW EXECUTE FUNCTION ecommify.set_updated_at();


--
-- Name: orders trg_orders_updated_at; Type: TRIGGER; Schema: ecommify; Owner: -
--

CREATE TRIGGER trg_orders_updated_at BEFORE UPDATE ON ecommify.orders FOR EACH ROW EXECUTE FUNCTION ecommify.set_updated_at();


--
-- Name: products trg_products_updated_at; Type: TRIGGER; Schema: ecommify; Owner: -
--

CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON ecommify.products FOR EACH ROW EXECUTE FUNCTION ecommify.set_updated_at();


--
-- Name: sellers trg_sellers_updated_at; Type: TRIGGER; Schema: ecommify; Owner: -
--

CREATE TRIGGER trg_sellers_updated_at BEFORE UPDATE ON ecommify.sellers FOR EACH ROW EXECUTE FUNCTION ecommify.set_updated_at();


--
-- Name: order_items order_items_order_sk_fkey; Type: FK CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.order_items
    ADD CONSTRAINT order_items_order_sk_fkey FOREIGN KEY (order_sk) REFERENCES ecommify.orders(order_sk) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: order_items order_items_product_sk_fkey; Type: FK CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.order_items
    ADD CONSTRAINT order_items_product_sk_fkey FOREIGN KEY (product_sk) REFERENCES ecommify.products(product_sk) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: order_items order_items_seller_sk_fkey; Type: FK CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.order_items
    ADD CONSTRAINT order_items_seller_sk_fkey FOREIGN KEY (seller_sk) REFERENCES ecommify.sellers(seller_sk) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: order_payments order_payments_order_sk_fkey; Type: FK CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.order_payments
    ADD CONSTRAINT order_payments_order_sk_fkey FOREIGN KEY (order_sk) REFERENCES ecommify.orders(order_sk) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: order_reviews order_reviews_order_sk_fkey; Type: FK CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.order_reviews
    ADD CONSTRAINT order_reviews_order_sk_fkey FOREIGN KEY (order_sk) REFERENCES ecommify.orders(order_sk) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: orders orders_customer_sk_fkey; Type: FK CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.orders
    ADD CONSTRAINT orders_customer_sk_fkey FOREIGN KEY (customer_sk) REFERENCES ecommify.customers(customer_sk) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: products products_category_sk_fkey; Type: FK CONSTRAINT; Schema: ecommify; Owner: -
--

ALTER TABLE ONLY ecommify.products
    ADD CONSTRAINT products_category_sk_fkey FOREIGN KEY (category_sk) REFERENCES ecommify.category_translation(category_sk) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--


