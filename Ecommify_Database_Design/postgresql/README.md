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
2. Ejecutar `seed_data/paso_06_crear_staging.sql`.
3. Ejecutar `seed_data/paso_07_cargar_csv_staging.sql`.
4. Ejecutar `seed_data/paso_08_insertar_modelo_final.sql`.
5. Ejecutar `seed_data/paso_09_validar_carga.sql`.
6. Ejecutar `queries/paso_07_refrescar_vistas_materializadas.sql`.
7. Usar `queries/paso_08_consultas_analiticas_ejemplo.sql` como consultas de control tecnico y analitica.
8. Conservar `schema/paso_06_borrador_particionamiento_orders.sql` como alternativa tecnica de particionamiento.

## Scripts principales

| Paso | Archivo | Proposito |
|---|---|---|
| 01 | `schema/paso_01_crear_esquema.sql` | Crear esquema `ecommify` y habilitar `pg_trgm` / PostGIS. |
| 02 | `schema/paso_02_crear_tablas_base.sql` | Crear tablas normalizadas, llaves tecnicas, restricciones, tipos avanzados controlados y columna espacial `geog`. |
| 03 | `schema/paso_03_crear_indices.sql` | Crear indices iniciales para IDs Olist, FK internas, OLTP, analitica, PostGIS y busqueda textual con `pg_trgm`. |
| 04 | `schema/paso_04_crear_triggers_updated_at.sql` | Crear funcion y triggers para `updated_at`. |
| 05 | `schema/paso_05_crear_vistas_materializadas.sql` | Crear vistas materializadas para tableros. |
| 06 | `schema/paso_06_borrador_particionamiento_orders.sql` | Alternativa tecnica de particionamiento y sus implicaciones fisicas. |
| 07 | `queries/paso_07_refrescar_vistas_materializadas.sql` | Poblar/refrescar vistas materializadas despues de cargar datos. |
| 08 | `queries/paso_08_consultas_analiticas_ejemplo.sql` | Consultas de control tecnico y analitica. |
| 09 | `queries/paso_09_benchmark_antes_despues_indices.sql` | Benchmark comparativo persistido en `benchmark_results`. |

## Scripts de carga CSV

| Paso | Archivo | Proposito |
|---|---|---|
| 06 | `seed_data/paso_06_crear_staging.sql` | Crear tablas staging alineadas con los CSV Olist. |
| 07 | `seed_data/paso_07_cargar_csv_staging.sql` | Cargar archivos CSV desde `/workspace/raw` usando `COPY`. |
| 08 | `seed_data/paso_08_insertar_modelo_final.sql` | Insertar datos limpios en tablas finales resolviendo llaves tecnicas. |
| 09 | `seed_data/paso_09_validar_carga.sql` | Validar conteos finales y columna espacial `geog`. |

La carga final mantiene este orden logico: categorias, clientes, sellers, productos, ordenes, items, pagos, resenas y geolocalizacion.

Las tablas hijas resuelven sus FK internas con `INSERT ... SELECT` desde staging. Por ejemplo, `orders.customer_sk` se obtiene desde `customers.customer_id`, y `order_items.product_sk` desde `products.product_id`.

## Artefactos cloud Supabase

La carpeta `cloud/` contiene artefactos generados para migrar el modelo final PostgreSQL/PostGIS hacia Supabase sin reemplazar Docker local.

| Archivo | Proposito |
|---|---|
| `cloud/cloud_supabase_schema.sql` | Export inicial del esquema `ecommify` desde Docker. |
| `cloud/cloud_supabase_schema_clean.sql` | Variante sin staging, sin `benchmark_results` y sin funcion de benchmark local. |
| `cloud/cloud_supabase_schema_supabase.sql` | Variante compatible con Supabase, ajustada al schema `extensions` para PostGIS y `pg_trgm`. |
| `cloud/cloud_supabase_data_bloque_01_catalogo.sql` | Primer bloque de datos migrado inicialmente con inserts por columnas; se conserva como evidencia operativa. |

Los datos restantes se cargaron mediante `pg_dump --data-only` en modo `COPY` desde archivos temporales dentro del contenedor, para evitar problemas de encoding y mejorar rendimiento. La evidencia completa esta en `docs/Evidencia_Migracion_Cloud_Supabase.md`.

## Evidencias

| Archivo | Proposito |
|---|---|
| `evidencias.md` | Documento academico con interpretacion de pruebas PostgreSQL, PostGIS, `pg_trgm`, vistas materializadas e indices OLTP. |
| `evidencias` | Salida cruda de consola usada como respaldo de trazabilidad. |
| Tabla `benchmark_results` | Resultados antes/despues de benchmarks PostgreSQL para construir tablas y graficos comparativos. |
| `docs/Evidencia_Migracion_Cloud_Supabase.md` | Evidencia de migracion PostgreSQL/PostGIS a Supabase, conteos, indices y planes `EXPLAIN ANALYZE`. |

## Decisiones aplicadas

- Los IDs de Olist se mantienen como `TEXT UNIQUE`.
- Las PK y FK relacionales usan `BIGINT GENERATED ALWAYS AS IDENTITY`.
- No se usa `uuid-ossp` en el alcance inicial.
- `pg_trgm` se habilita para busqueda textual aproximada mediante indices GIN `gin_trgm_ops`.
- PostGIS se habilita para representar `geolocation_clean.geog GEOGRAPHY(Point, 4326)` e indexarla con GiST.
- No se habilita `hstore`.
- `JSONB` se usa en `products.specifications` y `orders.lifecycle`.
- `TEXT[]` se usa en `products.photo_urls`.
- Pagos permanecen en `order_payments`; la regla natural `(order_sk, payment_sequential)` se conserva como `UNIQUE`.
- MongoDB consume documentos derivados, no reemplaza estas tablas.
- Supabase aloja una copia cloud validada del modelo final PostgreSQL/PostGIS; Docker local sigue siendo la fuente reproducible.
- `geolocation_clean.geog` se genera automaticamente desde longitud y latitud; no se carga manualmente desde CSV.





