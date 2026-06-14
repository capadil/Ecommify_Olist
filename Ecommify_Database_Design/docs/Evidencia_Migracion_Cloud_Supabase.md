# Evidencia de migracion cloud a Supabase

Este documento consolida la evidencia de migracion de PostgreSQL/PostGIS desde Docker local hacia Supabase. Docker se mantiene como fuente reproducible del proyecto; Supabase se valida como despliegue cloud relacional y espacial.

## 1. Alcance de la migracion

| Elemento | Decision |
|---|---|
| Origen | PostgreSQL/PostGIS local en Docker |
| Destino | Supabase PostgreSQL/PostGIS |
| Proyecto Supabase | Ecommify Olist |
| Region | us-east-2 |
| Motor Supabase | PostgreSQL 17.6 |
| Modelo migrado | Solo tablas finales del schema `ecommify` |
| Excluido | Tablas `stg_*` y `benchmark_results` |
| MongoDB | No se migra a Supabase; queda pendiente para MongoDB Atlas |

**Comentario importante:** se excluyeron staging y benchmarks locales para cuidar el limite del plan gratuito y mantener Supabase enfocado en el modelo final de datos. Docker conserva el flujo completo de reconstruccion desde CSV.

## 2. Diagnostico local antes de migrar

Se valido primero el estado de PostgreSQL local para asegurar que la migracion partiera de una base completa.

```powershell
docker compose exec postgres psql -U ecommify_user -d ecommify_db -c "\dt ecommify.*"
```

Resultado local: el schema `ecommify` contenia 19 tablas, incluyendo tablas finales, staging y `benchmark_results`.

| Tipo de objeto local | Resultado |
|---|---:|
| Tablas finales | 9 |
| Tablas staging | 9 |
| Tabla de benchmark | 1 |
| Total tablas locales | 19 |

Conteos locales principales:

| Tabla | Registros |
|---|---:|
| sellers | 3.095 |
| products | 32.951 |
| geolocation_clean | 27.912 |
| customers | 99.441 |
| order_items | 112.650 |
| orders | 99.441 |

Tamano local medido:

| Base | Tamano |
|---|---:|
| Docker PostgreSQL local | 369 MB |

**Comentario importante:** el tamano local incluye staging y evidencias de benchmark. Por eso la migracion a Supabase se diseno para llevar solo el modelo final.

## 3. Conexion y validacion inicial de Supabase

La conexion se realizo con una variable de PowerShell para evitar repetir la cadena de conexion y no dejar password escrito en comandos.

```powershell
$SUPABASE_DB_URL = "postgresql://postgres.qtwtpcrikdtqrlcodpkz@aws-1-us-east-2.pooler.supabase.com:5432/postgres?sslmode=require"
```

Validacion de version:

```sql
select version();
```

| Resultado | Valor |
|---|---|
| PostgreSQL Supabase | PostgreSQL 17.6 on aarch64-unknown-linux-gnu |

Validacion inicial de extensiones:

```sql
select extname, extversion
from pg_extension
where extname in ('postgis','pg_trgm');
```

| Extension | Version |
|---|---:|
| postgis | 3.3.7 |
| pg_trgm | 1.6 |

Tamano inicial de Supabase:

| Momento | Tamano |
|---|---:|
| Antes de importar | 18 MB |

## 4. Preparacion del DDL para Supabase

Se genero un DDL limpio desde Docker y se excluyeron objetos que no debian migrarse a Supabase.

Artefactos generados:

| Archivo | Proposito |
|---|---|
| `postgresql/cloud/cloud_supabase_schema.sql` | Export inicial del schema `ecommify`. |
| `postgresql/cloud/cloud_supabase_schema_clean.sql` | Variante sin staging, sin `benchmark_results` y sin funcion local de benchmark. |
| `postgresql/cloud/cloud_supabase_schema_supabase.sql` | Variante final compatible con Supabase. |

Durante la primera importacion del esquema limpio se presentaron errores por referencias a objetos de extensiones en `public`:

```text
ERROR: type "public.geography" does not exist
ERROR: operator class "public.gin_trgm_ops" does not exist for access method "gin"
```

Se verifico el schema real de las extensiones en Supabase:

```sql
select e.extname, n.nspname as extension_schema
from pg_extension e
join pg_namespace n on n.oid = e.extnamespace
where e.extname in ('postgis','pg_trgm');
```

| Extension | Schema en Supabase |
|---|---|
| postgis | extensions |
| pg_trgm | extensions |

**Comentario importante:** en Docker las referencias del dump apuntaban a `public`, pero en Supabase las extensiones estan en `extensions`. Por eso se creo una variante del DDL que reemplaza referencias como `public.geography`, `public.gin_trgm_ops`, `public.st_setsrid` y `public.st_makepoint` por sus equivalentes bajo `extensions`.

Antes de reimportar se limpio la importacion parcial:

```sql
drop schema if exists ecommify cascade;
```

Luego se ejecuto el DDL compatible:

```powershell
docker compose exec postgres psql $SUPABASE_DB_URL -f /tmp/cloud_supabase_schema_supabase.sql
```

## 5. Validacion del esquema en Supabase

Despues de importar el DDL corregido se validaron las tablas finales:

```sql
\dt ecommify.*
```

| Tabla final en Supabase |
|---|
| category_translation |
| customers |
| geolocation_clean |
| order_items |
| order_payments |
| order_reviews |
| orders |
| products |
| sellers |

Resultado: quedaron 9 tablas finales. No se migraron tablas staging ni `benchmark_results`.

## 6. Carga de datos

La carga se realizo desde Docker hacia Supabase con `pg_dump --data-only`.

Primero se probo un bloque pequeno con inserts por columnas:

| Bloque | Tablas | Resultado |
|---|---|---|
| Bloque 1 | `category_translation`, `sellers`, `products` | Cargado correctamente |

Conteos despues del Bloque 1:

| Tabla | Registros |
|---|---:|
| category_translation | 71 |
| sellers | 3.095 |
| products | 32.951 |

Tamano despues del Bloque 1:

| Momento | Tamano |
|---|---:|
| Despues de catalogo | 30 MB |

**Comentario importante:** el primer bloque con `--column-inserts` fue funcional, pero lento, porque genera un `INSERT` por fila. Para los siguientes bloques se uso carga bulk con `COPY`, que es mas eficiente para Supabase.

Carga de `customers` con `COPY`:

| Tabla | Resultado |
|---|---:|
| customers | 99.441 |

Tamano despues de `customers`:

| Momento | Tamano |
|---|---:|
| Despues de customers | 73 MB |

Carga de `orders` con `COPY`:

| Tabla | Resultado |
|---|---:|
| orders | 99.441 |

Tamano despues de `orders`:

| Momento | Tamano |
|---|---:|
| Despues de orders | 115 MB |

Carga restante con `COPY`:

| Tabla | Filas cargadas |
|---|---:|
| geolocation_clean | 27.912 |
| order_items | 112.650 |
| order_payments | 103.886 |
| order_reviews | 99.224 |

## 7. Validacion final de datos en Supabase

Conteos finales:

| Tabla | Registros |
|---|---:|
| category_translation | 71 |
| customers | 99.441 |
| sellers | 3.095 |
| products | 32.951 |
| orders | 99.441 |
| order_items | 112.650 |
| order_payments | 103.886 |
| order_reviews | 99.224 |
| geolocation_clean | 27.912 |

Validacion PostGIS:

```sql
select count(*) as geolocation_rows_with_geog
from ecommify.geolocation_clean
where geog is not null;
```

| Metrica | Resultado |
|---|---:|
| Filas con `geog` no nulo | 27.912 |

Tamano final:

| Momento | Tamano |
|---|---:|
| Supabase despues de carga completa | 210 MB |

**Comentario importante:** el tamano final quedo por debajo del limite aproximado del plan gratuito. Esto confirma que excluir staging y benchmarks locales fue una decision adecuada.

## 8. Validacion de extensiones e indices en SQL Editor

Extensiones en Supabase:

| Extension | Version | Schema |
|---|---:|---|
| postgis | 3.3.7 | extensions |
| pg_trgm | 1.6 | extensions |

Indices criticos validados:

| Indice |
|---|
| idx_category_name_trgm |
| idx_customers_city_trgm |
| idx_geolocation_clean_geog_gist |
| idx_order_reviews_message_trgm |
| idx_sellers_city_trgm |

**Comentario importante:** estos indices confirman que Supabase no solo recibio tablas y datos; tambien conserva las optimizaciones fisicas necesarias para busquedas textuales y espaciales.

## 9. Evidencias de rendimiento en Supabase

Los siguientes `EXPLAIN ANALYZE` se ejecutaron desde Supabase SQL Editor.

### 9.1 Consulta OLTP por `order_id`

Consulta evaluada:

```sql
explain analyze
select
    o.order_id,
    o.order_status,
    c.customer_id,
    op.payment_value
from ecommify.orders o
join ecommify.customers c
    on c.customer_sk = o.customer_sk
left join ecommify.order_payments op
    on op.order_sk = o.order_sk
where o.order_id = 'e481f51cbdc54678b7cc49136f2d6af7';
```

Resultado relevante:

| Elemento | Evidencia |
|---|---|
| Acceso principal | `Index Scan using idx_orders_order_id` |
| Join cliente | `Index Scan using customers_pkey` |
| Join pagos | `Index Scan using idx_order_payments_order_sk` |
| Execution Time | 14.619 ms |

### 9.2 Busqueda textual con `pg_trgm`

Consulta evaluada:

```sql
explain analyze
select
    customer_id,
    customer_city,
    customer_state
from ecommify.customers
where customer_city % 'sao paulo'
order by extensions.similarity(customer_city, 'sao paulo') desc
limit 20;
```

Resultado relevante:

| Elemento | Evidencia |
|---|---|
| Acceso | `Bitmap Index Scan on idx_customers_city_trgm` |
| Filas retornadas | 20 |
| Execution Time | 838.341 ms |

### 9.3 Consulta espacial con PostGIS

Consulta evaluada:

```sql
explain analyze
select
    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state
from ecommify.geolocation_clean
where extensions.ST_DWithin(
    geog,
    extensions.ST_SetSRID(
        extensions.ST_MakePoint(-46.6333, -23.5505),
        4326
    )::extensions.geography,
    5000
)
limit 20;
```

Resultado relevante:

| Elemento | Evidencia |
|---|---|
| Acceso | `Index Scan using idx_geolocation_clean_geog_gist` |
| Filas retornadas | 20 |
| Execution Time | 161.061 ms |

### 9.4 Vista materializada de ventas

Antes de consultar la vista materializada fue necesario refrescarla en Supabase, porque el DDL crea la definicion pero no conserva automaticamente los datos materializados.

```sql
refresh materialized view ecommify.mv_sales_by_category_monthly;
refresh materialized view ecommify.mv_customer_segments;
refresh materialized view ecommify.mv_seller_performance_monthly;
refresh materialized view ecommify.mv_geo_sales_summary;
```

Consulta evaluada:

```sql
explain analyze
select
    sales_month,
    category_name,
    total_value
from ecommify.mv_sales_by_category_monthly
where sales_month between date '2018-01-01' and date '2018-12-01'
order by total_value desc
limit 10;
```

Resultado relevante:

| Elemento | Evidencia |
|---|---|
| Acceso | `Index Scan using ux_mv_sales_by_category_monthly` |
| Filas retornadas | 10 |
| Execution Time | 3.160 ms |

**Comentario importante:** los tiempos de Supabase son mayores que Docker local por red, pooler, recursos compartidos del plan gratuito y estado de cache. Para esta actividad, la evidencia mas importante es el uso correcto de indices, extensiones y vistas con datos reales.

## 10. Conclusiones de la migracion

La migracion PostgreSQL/PostGIS hacia Supabase queda validada con datos reales y sin modificar la arquitectura local Docker.

| Criterio | Resultado |
|---|---|
| Docker preservado como fuente reproducible | Cumplido |
| DDL compatible ejecutado en Supabase | Cumplido |
| Datos finales cargados en Supabase | Cumplido |
| Staging excluido de Supabase | Cumplido |
| PostGIS operativo | Cumplido |
| `pg_trgm` operativo | Cumplido |
| Indices criticos presentes | Cumplido |
| Vistas materializadas refrescadas | Cumplido |
| Tamano final dentro del margen free tier | 210 MB |
| MongoDB Atlas | Pendiente |

La arquitectura cloud queda parcialmente implementada:

```text
PostgreSQL/PostGIS Docker local -> Supabase PostgreSQL/PostGIS: validado
MongoDB Docker local            -> MongoDB Atlas: pendiente
```
