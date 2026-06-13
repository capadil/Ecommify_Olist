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
- `review_documents` usa unicidad compuesta por `review_id` y `order_id`, porque el dataset puede asociar un identificador de resena con mas de una orden.
- Usar tipos de MongoDB: `object`, `array`, `string`, `number`, `date`, `boolean`.
- No usar tipos propios de PostgreSQL como `JSONB` dentro de esquemas MongoDB.

## Script de sincronizacion implementado

El repositorio incluye el script:

```text
tools/sync_postgres_to_mongo.py
```

Este script construye documentos derivados desde PostgreSQL y los escribe en MongoDB mediante `upsert`, conservando a PostgreSQL como fuente de verdad.

Ejecucion recomendada desde Docker:

```powershell
cd docker
docker compose run --rm mongo_sync
```

Dependencias del sincronizador:

```text
tools/requirements-sync.txt
```

La sincronizacion debe ejecutarse despues de:

1. Crear el esquema PostgreSQL.
2. Cargar los CSV Olist.
3. Insertar datos en el modelo final.
4. Refrescar vistas materializadas.
5. Crear colecciones MongoDB con validadores.
