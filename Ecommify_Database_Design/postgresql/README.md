# PostgreSQL - Borradores de ejecucion

Esta carpeta contiene los scripts borrador para el modelo relacional de Ecommify.

PostgreSQL es la fuente de verdad transaccional. Aqui se conservan las tablas base: `customers`, `orders`, `order_items`, `order_payments`, `products`, `sellers`, `category_translation`, `order_reviews` y `geolocation_clean`.

## Orden recomendado

1. Ejecutar scripts de `schema/` del paso 01 al paso 05.
2. Cargar datos en el orden indicado en `seed_data/README.md`.
3. Ejecutar `queries/paso_07_refrescar_vistas_materializadas.sql`.
4. Ejecutar `queries/paso_08_consultas_analiticas_ejemplo.sql` solo para validacion o demostracion.
5. Revisar `schema/paso_06_borrador_particionamiento_orders.sql` como decision tecnica, no como script obligatorio.

## Scripts principales

| Paso | Archivo | Proposito |
|---|---|---|
| 01 | `schema/paso_01_crear_esquema.sql` | Crear esquema `ecommify`. |
| 02 | `schema/paso_02_crear_tablas_base.sql` | Crear tablas normalizadas, restricciones y tipos avanzados controlados. |
| 03 | `schema/paso_03_crear_indices.sql` | Crear indices iniciales para OLTP y analitica. |
| 04 | `schema/paso_04_crear_triggers_updated_at.sql` | Crear funcion y triggers para `updated_at`. |
| 05 | `schema/paso_05_crear_vistas_materializadas.sql` | Crear vistas materializadas para dashboards. |
| 06 | `schema/paso_06_borrador_particionamiento_orders.sql` | Documentar alternativa de particionamiento; no ejecutar automaticamente. |
| 07 | `queries/paso_07_refrescar_vistas_materializadas.sql` | Poblar/refrescar vistas materializadas despues de cargar datos. |
| 08 | `queries/paso_08_consultas_analiticas_ejemplo.sql` | Consultas de validacion y analitica. |

## Decisiones aplicadas

- Los IDs de Olist se mantienen como `TEXT`.
- No se usa `uuid-ossp` en el alcance inicial.
- No se habilita `hstore`.
- `JSONB` se usa en `products.specifications` y `orders.lifecycle`.
- `TEXT[]` se usa en `products.photo_urls`.
- Pagos permanecen en `order_payments`; no se mueven a `JSONB`.
- MongoDB consume documentos derivados, no reemplaza estas tablas.
