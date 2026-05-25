# PostgreSQL - Diseno relacional

Esta carpeta contiene los scripts tecnicos del modelo relacional de Ecommify.

PostgreSQL es la fuente de verdad transaccional. Aqui se conservan las tablas base: `customers`, `orders`, `order_items`, `order_payments`, `products`, `sellers`, `category_translation`, `order_reviews` y `geolocation_clean`.

## Decision de llaves

El modelo usa dos niveles de identificacion:

| Tipo de llave | Ejemplo | Uso |
|---|---|---|
| Llave tecnica interna | `customer_sk`, `order_sk`, `product_sk` | PK y FK relacionales dentro de PostgreSQL. |
| ID original Olist | `customer_id`, `order_id`, `product_id` | Trazabilidad, busqueda operacional y enlace con archivos fuente. |

Esta decision evita usar IDs externos largos como PK fisicas, mejora el tamano de indices y conserva la trazabilidad del dataset. No se adopta `uuid-ossp` en el alcance inicial.

## Secuencia tecnica

1. Ejecutar scripts de `schema/` del paso 01 al paso 05.
2. Cargar datos en el orden indicado en `seed_data/README.md`.
3. Ejecutar `queries/paso_07_refrescar_vistas_materializadas.sql`.
4. Usar `queries/paso_08_consultas_analiticas_ejemplo.sql` como consultas de control tecnico y analitica.
5. Conservar `schema/paso_06_borrador_particionamiento_orders.sql` como alternativa tecnica de particionamiento.

## Scripts principales

| Paso | Archivo | Proposito |
|---|---|---|
| 01 | `schema/paso_01_crear_esquema.sql` | Crear esquema `ecommify`. |
| 02 | `schema/paso_02_crear_tablas_base.sql` | Crear tablas normalizadas, llaves tecnicas, restricciones y tipos avanzados controlados. |
| 03 | `schema/paso_03_crear_indices.sql` | Crear indices iniciales para IDs Olist, FK internas, OLTP y analitica. |
| 04 | `schema/paso_04_crear_triggers_updated_at.sql` | Crear funcion y triggers para `updated_at`. |
| 05 | `schema/paso_05_crear_vistas_materializadas.sql` | Crear vistas materializadas para tableros. |
| 06 | `schema/paso_06_borrador_particionamiento_orders.sql` | Alternativa tecnica de particionamiento y sus implicaciones fisicas. |
| 07 | `queries/paso_07_refrescar_vistas_materializadas.sql` | Poblar/refrescar vistas materializadas despues de cargar datos. |
| 08 | `queries/paso_08_consultas_analiticas_ejemplo.sql` | Consultas de control tecnico y analitica. |

## Decisiones aplicadas

- Los IDs de Olist se mantienen como `TEXT UNIQUE`.
- Las PK y FK relacionales usan `BIGINT GENERATED ALWAYS AS IDENTITY`.
- No se usa `uuid-ossp` en el alcance inicial.
- No se habilita `hstore`.
- `JSONB` se usa en `products.specifications` y `orders.lifecycle`.
- `TEXT[]` se usa en `products.photo_urls`.
- Pagos permanecen en `order_payments`; la regla natural `(order_sk, payment_sequential)` se conserva como `UNIQUE`.
- MongoDB consume documentos derivados, no reemplaza estas tablas.
