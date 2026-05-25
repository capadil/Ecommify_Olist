# PostgreSQL seed_data

Esta carpeta contiene criterios tecnicos para scripts de carga CSV o comandos `COPY`.

## Secuencia tecnica de carga

1. `category_translation`
2. `customers`
3. `sellers`
4. `products`
5. `orders`
6. `order_items`
7. `order_payments`
8. `order_reviews`
9. `geolocation_clean`

## Regla de carga con llaves tecnicas

Los archivos fuente de Olist traen IDs externos como `order_id`, `customer_id`, `product_id` y `seller_id`. En PostgreSQL esos campos se cargan como `TEXT UNIQUE`, pero las relaciones internas usan llaves tecnicas `*_sk`.

La carga de tablas hijas se apoya en staging tables o consultas `INSERT ... SELECT` que resuelven las llaves internas:

- `orders.customer_sk` se obtiene buscando `customers.customer_id`.
- `products.category_sk` se obtiene buscando `category_translation.product_category_name`.
- `order_items.order_sk` se obtiene buscando `orders.order_id`.
- `order_items.product_sk` se obtiene buscando `products.product_id`.
- `order_items.seller_sk` se obtiene buscando `sellers.seller_id`.
- `order_payments.order_sk` se obtiene buscando `orders.order_id`.
- `order_reviews.order_sk` se obtiene buscando `orders.order_id`.

## Criterios tecnicos

- Mantener IDs de Olist como `TEXT UNIQUE` para trazabilidad.
- No convertir IDs Olist a UUID de forma artificial.
- Limpiar o consolidar geolocalizacion antes de cargar `geolocation_clean`.
- Cargar `products.photo_urls` solo si Ecommify define URLs reales; Olist solo trae `product_photos_qty`.
- Refrescar vistas materializadas despues de cargar las tablas transaccionales.
