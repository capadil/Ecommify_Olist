# MongoDB - Diseno documental derivado

MongoDB se usa como capa derivada de lectura y analitica. No reemplaza a PostgreSQL como fuente de verdad.

## Relacion con las llaves PostgreSQL

PostgreSQL usa llaves tecnicas internas `*_sk` para PK/FK y conserva los IDs Olist como `TEXT UNIQUE`. MongoDB debe exponer los IDs Olist (`product_id`, `customer_id`, `seller_id`, `order_id`, `review_id`) porque son utiles para trazabilidad y lectura, pero no son la fuente de integridad relacional.

## Secuencia tecnica

1. Ejecutar primero los pasos 01 a 08 de PostgreSQL.
2. Refrescar las vistas materializadas en PostgreSQL.
3. Ejecutar `schema/paso_09_crear_colecciones_validadores.js`.
4. Ejecutar `tools/sync_postgres_to_mongo.py` desde Docker con `docker compose run --rm mongo_sync`.
5. Usar `queries/paso_10_consultas_analiticas_ejemplo.js` como consultas de control tecnico sobre documentos derivados.
6. Guardar la interpretacion academica en `mongodb/evidencias.md` y conservar la salida cruda en `mongodb/evidencias`.

## Scripts principales

| Paso | Archivo | Proposito |
|---|---|---|
| 09 | `schema/paso_09_crear_colecciones_validadores.js` | Crear colecciones, validadores e indices de MongoDB. |
| 10 | `queries/paso_10_consultas_analiticas_ejemplo.js` | Consultas de ejemplo sobre documentos derivados. |
| 11 | `queries/paso_11_benchmark_antes_despues_indices.js` | Benchmark comparativo persistido en `benchmark_results`. |

## Fuentes documentales derivadas

| Coleccion | Fuente PostgreSQL |
|---|---|
| `product_catalog` | `products`, `category_translation`, `order_items`, `order_reviews` |
| `customer_profiles` | `mv_customer_segments` |
| `seller_performance` | `mv_seller_performance_monthly` |
| `geo_analytics` | `mv_geo_sales_summary` |
| `review_documents` | `order_reviews`, `orders`, `customers`, `order_items`, `products` |


## Despliegue cloud MongoDB Atlas

MongoDB Atlas aloja la copia cloud validada de la capa documental derivada. Docker local sigue siendo la fuente reproducible para reconstruir las colecciones desde PostgreSQL.

La comunicacion cloud recomendada no conecta Atlas directamente contra Supabase. Se ejecuta el sincronizador externo `tools/sync_postgres_to_mongo.py`, leyendo desde PostgreSQL/Supabase y escribiendo en Atlas con operaciones idempotentes. Para ese modo, el script acepta `SUPABASE_DATABASE_URL` o `POSTGRES_DSN` para PostgreSQL, y `ATLAS_URI` o `MONGO_URI` para MongoDB. Si las credenciales de Atlas se mantienen separadas, tambien acepta `ATLAS_USER` y `ATLAS_USER_PASS`.

| Aspecto | Resultado |
|---|---|
| Cluster | `ecommify-atlas` |
| Base | `ecommify_analytics` |
| Colecciones migradas | 5 colecciones de negocio |
| Metodo de carga | `mongodump` local + `mongorestore` hacia Atlas |
| Documentos restaurados | 256.417 documentos, 0 fallos |
| Coleccion excluida del resultado final | `benchmark_results` |
| Evidencia | `docs/Evidencia_Migracion_Cloud_MongoDB_Atlas.md` |

Conteos finales validados en Atlas:

| Coleccion | Documentos |
|---|---:|
| `product_catalog` | 32.951 |
| `customer_profiles` | 99.441 |
| `seller_performance` | 3.095 |
| `geo_analytics` | 21.698 |
| `review_documents` | 99.224 |
## Evidencias

| Archivo | Proposito |
|---|---|
| `evidencias.md` | Documento academico con interpretacion de indices, conteos, sincronizacion y consultas analiticas MongoDB. |
| `evidencias` | Salida cruda de consola usada como respaldo de trazabilidad. |
| Coleccion `benchmark_results` | Resultados antes/despues de benchmarks MongoDB local para calcular `executionTimeMillis` y ratios de eficiencia. No se conserva como coleccion funcional en Atlas. |
| `docs/Evidencia_Migracion_Cloud_MongoDB_Atlas.md` | Evidencia de migracion MongoDB Docker -> MongoDB Atlas, indices, restore y conteos finales. |
## Decisiones aplicadas

- Usar tipos documentales de MongoDB: `object`, `array`, `string`, `number`, `date`, `boolean`.
- No usar `JSONB` en MongoDB.
- Colecciones derivadas: `product_catalog`, `customer_profiles`, `seller_performance`, `geo_analytics`, `review_documents`.
- Conservar IDs Olist en documentos para trazabilidad.
- `review_documents` usa indice unico compuesto `{ review_id: 1, order_id: 1 }`, porque el dataset puede asociar un mismo `review_id` con mas de una orden.
- No modelar `*_sk` como requisito de consulta documental, salvo que se necesite auditoria interna de sincronizacion.
- Los documentos se actualizan con `upsert`; repetir la sincronizacion no debe duplicar informacion.
- MongoDB Atlas aloja la copia cloud validada de las colecciones derivadas; no reemplaza a PostgreSQL/Supabase como fuente relacional.



