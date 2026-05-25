# MongoDB seed_data

Esta carpeta contiene criterios tecnicos para scripts o archivos de carga de documentos derivados.

MongoDB no es fuente de verdad. Sus colecciones se deben construir desde PostgreSQL.

## Fuentes recomendadas

- `product_catalog`: `products`, `category_translation`, `order_items`, `order_reviews`.
- `customer_profiles`: `customers`, `orders`, `order_payments`, `order_reviews`.
- `seller_performance`: `sellers`, `order_items`, `orders`, `order_reviews`.
- `geo_analytics`: `geolocation_clean`, `customers`, `sellers`, `orders`, `order_payments`.
- `review_documents`: `order_reviews`, `orders`, `order_items`, `products`, `customers`.

## Reglas

- PostgreSQL permanece como fuente de verdad.
- PostgreSQL usa `*_sk` para integridad relacional interna.
- MongoDB conserva IDs Olist en los documentos para trazabilidad y busqueda.
- Los documentos MongoDB pueden refrescarse periodicamente.
- Usar tipos de MongoDB: `object`, `array`, `string`, `number`, `date`, `boolean`.
- No usar tipos propios de PostgreSQL como `JSONB` dentro de esquemas MongoDB.
