# Evidencias PostgreSQL - Actividad 2

Este documento consolida las evidencias de ejecucion y validacion del componente PostgreSQL dentro del ambiente Docker local de Ecommify. PostgreSQL se mantiene como fuente de verdad transaccional del proyecto y concentra las tablas normalizadas, restricciones, llaves tecnicas, extensiones, indices y vistas materializadas.

La salida completa de consola se conserva en `postgresql/evidencias` como evidencia cruda. Este archivo presenta una lectura academica de los resultados obtenidos.

## 1. Objetivo de la validacion

Las pruebas ejecutadas buscan demostrar que la implementacion fisica en PostgreSQL esta alineada con las decisiones del README principal:

- Uso de PostgreSQL como base OLTP principal.
- Separacion entre tablas transaccionales y estructuras analiticas derivadas.
- Aplicacion de PostGIS para consultas geograficas.
- Aplicacion de `pg_trgm` para busqueda textual aproximada.
- Uso de indices para mejorar consultas por ID, texto, FK y geografia.
- Construccion y consulta de vistas materializadas para analitica.

## 2. Validacion de pg_trgm en clientes

Comando ejecutado:

```powershell
docker compose exec postgres psql -U ecommify_user -d ecommify_db -c "SET search_path TO ecommify, public; EXPLAIN ANALYZE SELECT customer_id, customer_city, customer_state FROM customers WHERE customer_city % 'sao paulo' ORDER BY similarity(customer_city, 'sao paulo') DESC;"
```

Resultado relevante:

```text
Bitmap Heap Scan on customers
  Recheck Cond: (customer_city % 'sao paulo'::text)
  -> Bitmap Index Scan on idx_customers_city_trgm
     Index Cond: (customer_city % 'sao paulo'::text)
Execution Time: 58.819 ms
```

Interpretacion:

La evidencia demuestra que el indice `idx_customers_city_trgm` fue utilizado por el optimizador mediante `Bitmap Index Scan`. Esto confirma que la extension `pg_trgm` no quedo solo declarada, sino aplicada en una capacidad concreta: busqueda aproximada sobre ciudades de clientes.

Academicamente, esta prueba valida el criterio de diseno para consultas tolerantes a variaciones textuales, errores de escritura o diferencias menores en nombres de ciudad. Es una extension pertinente para campos de texto provenientes de datos externos como Olist.

## 3. Validacion de pg_trgm en comentarios de resenas

Comando ejecutado:

```powershell
docker compose exec postgres psql -U ecommify_user -d ecommify_db -c "SET search_path TO ecommify, public; EXPLAIN ANALYZE SELECT review_id, review_score, review_comment_message FROM order_reviews WHERE review_comment_message % 'produto excelente' ORDER BY similarity(review_comment_message, 'produto excelente') DESC LIMIT 20;"
```

Resultado relevante:

```text
Bitmap Heap Scan on order_reviews
  Recheck Cond: (review_comment_message % 'produto excelente'::text)
  -> Bitmap Index Scan on idx_order_reviews_message_trgm
     Index Cond: (review_comment_message % 'produto excelente'::text)
Execution Time: 224.502 ms
```

Interpretacion:

El plan de ejecucion confirma el uso del indice `idx_order_reviews_message_trgm`. Esta evidencia respalda la decision de usar `pg_trgm` para textos no estructurados o semiestructurados, como comentarios de resenas.

La consulta permite localizar comentarios semanticamente cercanos a una expresion sin requerir coincidencia exacta. Para el proyecto, esto aporta valor en escenarios de analisis de satisfaccion, revision de reclamos y exploracion de opiniones de clientes.

## 4. Validacion de PostGIS en geolocalizacion

Comando ejecutado:

```powershell
docker compose exec postgres psql -U ecommify_user -d ecommify_db -c "SET search_path TO ecommify, public; EXPLAIN ANALYZE SELECT geolocation_zip_code_prefix, geolocation_city, geolocation_state FROM geolocation_clean WHERE ST_DWithin(geog, ST_SetSRID(ST_MakePoint(-46.6333, -23.5505), 4326)::geography, 5000) LIMIT 20;"
```

Resultado relevante:

```text
Bitmap Heap Scan on geolocation_clean
  Filter: st_dwithin(...)
  -> Bitmap Index Scan on idx_geolocation_clean_geog_gist
     Index Cond: (geog && _st_expand(...))
Execution Time: 26.524 ms
```

Interpretacion:

La evidencia demuestra que PostGIS esta operativo sobre la columna `geog` y que PostgreSQL utiliza el indice espacial `idx_geolocation_clean_geog_gist`. La funcion `ST_DWithin` permite buscar registros ubicados dentro de un radio geografico, en este caso 5 km alrededor de un punto cercano a Sao Paulo.

Esto valida la decision de modelar `geolocation_clean.geog` como `GEOGRAPHY(Point, 4326)`. A diferencia de almacenar latitud y longitud como valores numericos aislados, PostGIS permite consultas espaciales con semantica geografica e indices especializados.

## 5. Validacion de vista materializada de ventas

Comando ejecutado:

```powershell
docker compose exec postgres psql -U ecommify_user -d ecommify_db -c "SET search_path TO ecommify, public; EXPLAIN ANALYZE SELECT sales_month, category_name, total_value FROM mv_sales_by_category_monthly WHERE sales_month BETWEEN DATE '2018-01-01' AND DATE '2018-12-01' ORDER BY total_value DESC LIMIT 10;"
```

Resultado relevante:

```text
Seq Scan on mv_sales_by_category_monthly
  Filter: sales_month BETWEEN '2018-01-01' AND '2018-12-01'
Sort Method: top-N heapsort
Execution Time: 0.314 ms
```

Interpretacion:

Aunque el plan usa `Seq Scan`, el tiempo de ejecucion es muy bajo porque la vista materializada ya contiene datos agregados. Esto valida la separacion OLTP/OLAP: las consultas analiticas no recorren directamente todas las tablas transaccionales, sino una estructura derivada preparada para dashboards.

Esta evidencia respalda la decision de usar vistas materializadas como mecanismo de analitica controlada dentro de PostgreSQL.

## 6. Validacion de consulta OLTP por order_id

Comando ejecutado:

```powershell
docker compose exec postgres psql -U ecommify_user -d ecommify_db -c "SET search_path TO ecommify, public; EXPLAIN ANALYZE SELECT o.order_id, o.order_status, c.customer_id, op.payment_value FROM orders o JOIN customers c ON c.customer_sk = o.customer_sk LEFT JOIN order_payments op ON op.order_sk = o.order_sk WHERE o.order_id = 'e481f51cbdc54678b7cc49136f2d6af7';"
```

Resultado relevante:

```text
Index Scan using idx_orders_order_id on orders
Index Scan using customers_pkey on customers
Index Scan using idx_order_payments_order_sk on order_payments
Execution Time: 0.145 ms
```

Interpretacion:

La consulta valida un caso OLTP tipico: recuperar una orden especifica, su cliente y sus pagos. El plan usa indices sobre `order_id`, la PK de `customers` y la FK de pagos. Esto confirma que el modelo fisico soporta busquedas transaccionales puntuales de baja latencia.

El resultado tambien evidencia la utilidad de conservar IDs Olist como `TEXT UNIQUE` para trazabilidad, mientras las relaciones internas se resuelven con llaves tecnicas `*_sk`.

## 7. Conclusiones

Las evidencias permiten concluir que la implementacion PostgreSQL cumple el alcance definido:

- Las extensiones `pg_trgm` y PostGIS fueron aplicadas con indices y consultas concretas.
- Los indices definidos son utilizados por el optimizador en busquedas textuales, geograficas y transaccionales.
- Las vistas materializadas funcionan como capa analitica derivada.
- PostgreSQL conserva su rol de fuente de verdad transaccional.
- La separacion OLTP/OLAP queda demostrada mediante consultas sobre tablas base y vistas materializadas.

