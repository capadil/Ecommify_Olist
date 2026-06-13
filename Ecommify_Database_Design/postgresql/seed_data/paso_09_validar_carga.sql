-- Ecommify Database Design
-- Paso 09: validar conteos principales despues de cargar el dataset Olist.

SET search_path TO ecommify, public;

SELECT 'category_translation' AS table_name, COUNT(*) AS rows_count FROM category_translation
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'geolocation_clean', COUNT(*) FROM geolocation_clean
ORDER BY table_name;

SELECT COUNT(*) AS geolocation_rows_with_geog
FROM geolocation_clean
WHERE geog IS NOT NULL;