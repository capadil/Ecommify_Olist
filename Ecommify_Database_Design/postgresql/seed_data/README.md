# PostgreSQL seed_data

Esta carpeta queda reservada para scripts de carga CSV o comandos `COPY`.

## Orden recomendado de carga

1. `category_translation`
2. `customers`
3. `sellers`
4. `products`
5. `orders`
6. `order_items`
7. `order_payments`
8. `order_reviews`
9. `geolocation_clean`

## Notas

- Mantener IDs de Olist como `TEXT`.
- Limpiar o consolidar geolocalizacion antes de cargar `geolocation_clean`.
- Cargar `products.photo_urls` solo si Ecommify define URLs reales; Olist solo trae `product_photos_qty`.
- Refrescar vistas materializadas despues de cargar las tablas transaccionales.
