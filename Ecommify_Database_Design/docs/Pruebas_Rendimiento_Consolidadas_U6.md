# Pruebas de rendimiento consolidadas - Unidad 6

Este documento consolida las pruebas de rendimiento y validacion existentes en el repositorio Ecommify Olist. Su objetivo es servir como indice tecnico de evidencias para la entrega final, sin duplicar por completo los documentos de implementacion, migracion y evidencias crudas.

## 1. Alcance

Las pruebas disponibles cubren:

- Benchmarks antes/despues de indices en PostgreSQL.
- Benchmarks antes/despues de indices en MongoDB.
- Validacion de uso de indices y extensiones en Supabase.
- Validacion de indices y consultas representativas en MongoDB Atlas.
- Validacion de conteos finales y consistencia de carga.

No existe todavia una suite formal de carga concurrente con herramientas como k6, Locust o JMeter. Esa brecha se documenta como limitacion y recomendacion de siguiente iteracion.

## 2. Fuentes de evidencia

| Evidencia | Archivo |
|---|---|
| Implementacion tecnica y resumen de benchmarks | `docs/Documento_Tecnico_Implementacion_U5_Actividad_2.md` |
| Evidencia PostgreSQL local | `postgresql/evidencias.md` y `postgresql/evidencias` |
| Evidencia MongoDB local | `mongodb/evidencias.md` y `mongodb/evidencias` |
| Benchmark PostgreSQL antes/despues | `postgresql/queries/paso_09_benchmark_antes_despues_indices.sql` |
| Benchmark MongoDB antes/despues | `mongodb/queries/paso_11_benchmark_antes_despues_indices.js` |
| Validacion Supabase | `docs/Evidencia_Migracion_Cloud_Supabase.md` |
| Validacion MongoDB Atlas | `docs/Evidencia_Migracion_Cloud_MongoDB_Atlas.md` |
| Analisis final U6 | `docs/Informe_Tecnico_Integral_U6_Etapa_2.md` |

## 3. Metodologia aplicada

### 3.1 PostgreSQL

La prueba PostgreSQL compara un escenario base contra un escenario optimizado:

1. Escenario base: se deshabilitaron `enable_indexscan` y `enable_bitmapscan` en la sesion para forzar planes menos favorables.
2. Escenario optimizado: se restauro el plan normal con indices.
3. Se midieron tiempos con `EXPLAIN ANALYZE`.
4. Se validaron consultas OLTP, busqueda textual con `pg_trgm`, consulta espacial PostGIS y vista materializada.

### 3.2 MongoDB

La prueba MongoDB compara recorrido natural contra uso de indices:

1. Escenario base: `hint({ $natural: 1 })` para forzar recorrido de coleccion.
2. Escenario optimizado: `hint()` sobre el indice esperado.
3. Se usaron metricas de `explain("executionStats")`.
4. Se priorizaron `totalDocsExamined`, `totalKeysExamined`, `nReturned` y `efficiency_ratio`.

### 3.3 Cloud

En cloud se validaron:

- Supabase PostgreSQL/PostGIS con datos reales, extensiones, indices y vistas materializadas.
- MongoDB Atlas con colecciones restauradas, indices y consultas representativas.
- Conteos finales contra el modelo validado previamente.

Los tiempos cloud no se interpretan como benchmark definitivo de capacidad productiva porque dependen de red, plan gratuito, cache y recursos compartidos.

## 4. Resultados PostgreSQL

| Consulta critica | Antes | Despues | Mejora |
|---|---:|---:|---:|
| OLTP order lookup | 25,899 ms | 0,043 ms | 99,83% menos tiempo |
| `pg_trgm` customer city search | 136,633 ms | 46,813 ms | 65,74% menos tiempo |
| PostGIS radius search | 26,105 ms | 0,351 ms | 98,66% menos tiempo |
| Materialized view sales dashboard | No aplica | 0,231 ms | Lectura preagregada |

Interpretacion:

- Los indices B-tree sobre IDs y FK internas son criticos para consultas OLTP.
- `pg_trgm` reduce el costo de busquedas textuales aproximadas, aunque sigue siendo mas costoso que una consulta por llave.
- PostGIS con GiST ofrece una mejora fuerte para filtros espaciales.
- Las vistas materializadas reducen el costo de dashboards recurrentes al leer datos preagregados.

## 5. Resultados MongoDB

| Consulta | Antes docs examinados | Despues docs examinados | Reduccion |
|---|---:|---:|---:|
| `product_catalog` por categoria | 353 | 20 | 94,33% |
| `customer_profiles` por estado | 39 | 20 | 48,72% |
| `geo_analytics` por estado/ciudad | 20.888 | 20 | 99,90% |
| `review_documents` por baja calificacion | 157 | 20 | 87,26% |

Interpretacion:

- Los documentos derivados son eficientes cuando el indice coincide con el patron de lectura.
- `geo_analytics` muestra el mayor beneficio por el indice compuesto `{ state: 1, city: 1 }`.
- En consultas con tiempos de 0 ms, la metrica mas util es el numero de documentos examinados, no solo `executionTimeMillis`.

## 6. Validacion cloud

### 6.1 Supabase

| Evidencia | Resultado |
|---|---:|
| PostgreSQL | 17.6 |
| PostGIS | 3.3.7 |
| `pg_trgm` | 1.6 |
| Tablas finales | 9 |
| Tamano final | 210 MB |
| Filas con `geog` PostGIS | 27.912 |

Consultas representativas en Supabase:

| Query critica | Acceso observado | Execution Time |
|---|---|---:|
| OLTP por `order_id` | `idx_orders_order_id`, PK clientes, FK pagos | 14,619 ms |
| `pg_trgm` por ciudad | `idx_customers_city_trgm` con Bitmap Index Scan | 838,341 ms |
| PostGIS por radio | `idx_geolocation_clean_geog_gist` con Index Scan | 161,061 ms |
| Vista materializada de ventas | `ux_mv_sales_by_category_monthly` | 3,160 ms |

### 6.2 MongoDB Atlas

| Coleccion | Documentos |
|---|---:|
| `product_catalog` | 32.951 |
| `customer_profiles` | 99.441 |
| `seller_performance` | 3.095 |
| `geo_analytics` | 21.698 |
| `review_documents` | 99.224 |

Consultas representativas en Atlas:

| Coleccion | Indice validado | Documentos retornados | Documentos examinados | Llaves examinadas |
|---|---|---:|---:|---:|
| `product_catalog` | `category.translated_name_1` | 20 | 20 | 20 |
| `customer_profiles` | `location.state_1` | 20 | 20 | 20 |
| `geo_analytics` | `state_1_city_1` | 20 | 20 | 20 |
| `review_documents` | `review_score_1` | 0 | 0 | 0 |

La consulta de `review_documents` valido disponibilidad del indice, pero no sirve como evidencia fuerte de eficiencia con resultados porque el filtro evaluado no retorno documentos en Atlas.

## 7. Limitaciones

| Limitacion | Impacto | Recomendacion |
|---|---|---|
| No hay suite formal de concurrencia | No se mide throughput ni degradacion con usuarios simultaneos. | Crear pruebas k6, Locust o JMeter para consultas criticas. |
| Free tier cloud | Tiempos variables por recursos compartidos. | Repetir pruebas en planes dedicados antes de produccion. |
| Sharding no ejecutado | La arquitectura sharded queda teorica en Atlas Free Cluster. | Validar en cluster dedicado si crecen datos o trafico. |
| Sincronizacion batch | Atlas puede quedar desactualizado entre ejecuciones. | Evolucionar a sincronizacion incremental, outbox o CDC. |
| Dataset historico | No representa escrituras transaccionales en tiempo real. | Simular operaciones futuras con carga sintetica controlada. |

## 8. Recomendacion de siguiente suite de carga

Para completar una evaluacion de rendimiento productiva se recomienda crear una carpeta `tests/load/` con:

| Prueba | Herramienta sugerida | Metrica |
|---|---|---|
| Consulta OLTP por `order_id` | k6 o Locust | p95 latency, throughput, error rate |
| Catalogo por categoria | k6 o Locust | p95 latency, documentos examinados |
| Dashboard geografico | k6 o Locust | p95 latency y saturacion de lectura |
| Sincronizacion batch/incremental | Script Python programado | duracion, documentos procesados, errores |

Esta suite debe ejecutarse contra un ambiente de staging, no contra credenciales personales ni servicios gratuitos de entrega academica.

## 9. Conclusion

El repositorio contiene evidencia cuantitativa suficiente para demostrar optimizacion de consultas e indices en PostgreSQL, MongoDB, Supabase y Atlas. La principal brecha frente a una evaluacion productiva completa es la ausencia de pruebas formales de carga concurrente y escalabilidad con datos 10x. Esa brecha queda identificada y vinculada al plan de escalamiento del informe integral U6.
