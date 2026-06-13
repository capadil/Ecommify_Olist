-- Ecommify Database Design
-- Paso 07: cargar CSV originales de Olist en tablas staging.
-- Requiere que Docker monte la carpeta raw en /workspace/raw.

SET search_path TO ecommify, public;

\copy stg_category_translation FROM '/workspace/raw/product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');
\copy stg_customers FROM '/workspace/raw/olist_customers_dataset.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy stg_sellers FROM '/workspace/raw/olist_sellers_dataset.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy stg_products FROM '/workspace/raw/olist_products_dataset.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy stg_orders FROM '/workspace/raw/olist_orders_dataset.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy stg_order_items FROM '/workspace/raw/olist_order_items_dataset.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy stg_order_payments FROM '/workspace/raw/olist_order_payments_dataset.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy stg_order_reviews FROM '/workspace/raw/olist_order_reviews_dataset.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');
\copy stg_geolocation FROM '/workspace/raw/olist_geolocation_dataset.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', QUOTE '"', ENCODING 'UTF8');