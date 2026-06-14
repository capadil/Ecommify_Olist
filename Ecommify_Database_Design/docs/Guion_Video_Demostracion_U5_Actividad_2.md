# Guion de video de demostracion - Unidad 5 Actividad 2

Duracion sugerida: 5 a 10 minutos.

Objetivo del video: demostrar que la arquitectura cloud objetivo de Ecommify funciona con Supabase como capa PostgreSQL/PostGIS y MongoDB Atlas como capa documental derivada. Docker se presenta como ambiente reproducible de preparacion, normalizacion, pruebas y migracion, no como destino final.

## 0. Preparacion antes de grabar

Antes de iniciar el video, dejar abiertas o disponibles estas herramientas:

| Herramienta | Uso en el video |
|---|---|
| Supabase SQL Editor | Mostrar conexion, tablas, extensiones, conteos y queries optimizadas PostgreSQL/PostGIS. |
| MongoDB Atlas | Mostrar cluster, base `ecommify_analytics`, colecciones e indices. |
| PowerShell en carpeta `docker/` | Ejecutar comandos de validacion sin exponer credenciales. |
| Repositorio local | Mostrar README, documento tecnico y evidencias si se requiere respaldo. |

Variables que deben existir en PowerShell, sin mostrar passwords en pantalla:

```powershell
$SUPABASE_DATABASE_URL = "postgresql://...:PASSWORD@.../postgres?sslmode=require"
$ATLAS_URI = "mongodb+srv://cluster-url/"
$ATLAS_USER = "usuario_atlas"
$ATLAS_USER_PASS = "password_atlas"
```

**Nota para la grabacion:** no activar opciones que muestren password. Si se necesita demostrar que las variables existen, mostrar solo los nombres, no los valores.

## 1. Introduccion y arquitectura objetivo

Tiempo sugerido: 45 segundos.

Mostrar: `README.md`, seccion de arquitectura cloud objetivo.

Narracion sugerida:

> En esta actividad se implementa la arquitectura cloud objetivo de Ecommify. Supabase aloja PostgreSQL/PostGIS como fuente de verdad relacional, transaccional y espacial. MongoDB Atlas aloja la capa documental derivada para consultas de lectura y analitica. Docker no es el destino final; se usa como ambiente reproducible para normalizar, validar scripts, preparar cargas y generar los artefactos de migracion.

Diagrama verbal:

```text
Supabase PostgreSQL/PostGIS -> job de sincronizacion -> MongoDB Atlas
```

Punto clave:

- PostgreSQL/Supabase es la fuente de verdad.
- MongoDB Atlas contiene documentos derivados.
- La sincronizacion es de una sola via: PostgreSQL hacia MongoDB.

## 2. Conexion a Supabase

Tiempo sugerido: 1 minuto.

Mostrar: Supabase SQL Editor o PowerShell.

### Opcion A: desde Supabase SQL Editor

Ejecutar:

```sql
select
    current_database() as database_name,
    current_user as connected_user,
    version() as postgres_version;
```

Luego ejecutar:

```sql
select
    e.extname as extension_name,
    e.extversion as version,
    n.nspname as schema_name
from pg_extension e
join pg_namespace n on n.oid = e.extnamespace
where e.extname in ('postgis', 'pg_trgm')
order by e.extname;
```

Resultado esperado:

| Extension | Resultado esperado |
|---|---|
| `postgis` | Disponible en Supabase |
| `pg_trgm` | Disponible en Supabase |

Narracion sugerida:

> Primero valido que estoy conectado a Supabase y que el proyecto tiene habilitadas las extensiones requeridas. PostGIS permite consultas espaciales y `pg_trgm` permite busquedas textuales aproximadas. En Supabase estas extensiones estan bajo el schema `extensions`, por eso el DDL cloud fue ajustado para ser compatible.

## 3. Navegacion por tablas principales en Supabase

Tiempo sugerido: 1 minuto.

Mostrar: Table Editor de Supabase o SQL Editor.

Ejecutar:

```sql
select table_name
from information_schema.tables
where table_schema = 'ecommify'
  and table_type = 'BASE TABLE'
order by table_name;
```

Ejecutar conteos:

```sql
select 'category_translation' as tabla, count(*) as registros from ecommify.category_translation
union all select 'customers', count(*) from ecommify.customers
union all select 'sellers', count(*) from ecommify.sellers
union all select 'products', count(*) from ecommify.products
union all select 'orders', count(*) from ecommify.orders
union all select 'order_items', count(*) from ecommify.order_items
union all select 'order_payments', count(*) from ecommify.order_payments
union all select 'order_reviews', count(*) from ecommify.order_reviews
union all select 'geolocation_clean', count(*) from ecommify.geolocation_clean
order by tabla;
```

Resultado esperado:

| Tabla | Registros esperados |
|---|---:|
| `category_translation` | 71 |
| `customers` | 99.441 |
| `sellers` | 3.095 |
| `products` | 32.951 |
| `orders` | 99.441 |
| `order_items` | 112.650 |
| `order_payments` | 103.886 |
| `order_reviews` | 99.224 |
| `geolocation_clean` | 27.912 |

Narracion sugerida:

> En Supabase no se migraron tablas staging ni tablas de benchmark local. Solo se llevo el modelo final, ya normalizado y validado en Docker. Esto reduce consumo del plan gratuito y deja en cloud las tablas necesarias para operacion relacional, espacial y analitica.

## 4. Query optimizada en Supabase: busqueda OLTP por orden

Tiempo sugerido: 1 minuto.

Mostrar: SQL Editor.

Ejecutar:

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

Que mostrar:

- `Index Scan using idx_orders_order_id`.
- Uso de PK en `customers`.
- Uso de indice sobre `order_payments.order_sk`.
- `Execution Time`.

Narracion sugerida:

> Esta consulta representa un patron OLTP: buscar una orden puntual con su cliente y pagos. El plan usa indices B-tree sobre el identificador de orden y las llaves internas. Esto valida la decision de mantener PostgreSQL como fuente de verdad transaccional, porque permite integridad, joins eficientes y busquedas exactas.

## 5. Query optimizada en Supabase: PostGIS

Tiempo sugerido: 1 minuto.

Mostrar: SQL Editor.

Ejecutar:

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

Que mostrar:

- `Index Scan using idx_geolocation_clean_geog_gist`.
- Uso de PostGIS con `ST_DWithin`.
- `Execution Time`.

Narracion sugerida:

> Esta consulta usa PostGIS para buscar ubicaciones dentro de un radio de cinco kilometros. La columna `geog` y el indice GiST permiten que PostgreSQL resuelva el filtro espacial sin recorrer toda la tabla. Esta fue una de las optimizaciones clave del modelo fisico.

## 6. Conexion a MongoDB Atlas

Tiempo sugerido: 1 minuto.

Mostrar: PowerShell o Atlas UI.

Comando desde carpeta `docker/`:

```powershell
docker compose exec mongo mongosh $ATLAS_URI --apiVersion 1 --username $ATLAS_USER --password $ATLAS_USER_PASS --eval "db.runCommand({ ping: 1 })"
```

Resultado esperado:

```javascript
{ ok: 1 }
```

Narracion sugerida:

> Ahora valido la conexion a MongoDB Atlas desde el entorno de trabajo. Atlas aloja la capa documental derivada. No reemplaza a Supabase, sino que recibe documentos preparados para lectura y analitica.

## 7. Navegacion por colecciones principales en MongoDB Atlas

Tiempo sugerido: 1 minuto.

Mostrar: MongoDB Atlas Collections o `mongosh`.

Comando:

```powershell
docker compose exec mongo mongosh $ATLAS_URI --apiVersion 1 --username $ATLAS_USER --password $ATLAS_USER_PASS --eval "const dbx=db.getSiblingDB('ecommify_analytics'); ['product_catalog','customer_profiles','seller_performance','geo_analytics','review_documents'].forEach(c => print(c + ': ' + dbx[c].countDocuments()));"
```

Resultado esperado:

| Coleccion | Documentos esperados |
|---|---:|
| `product_catalog` | 32.951 |
| `customer_profiles` | 99.441 |
| `seller_performance` | 3.095 |
| `geo_analytics` | 21.698 |
| `review_documents` | 99.224 |

Narracion sugerida:

> Estas colecciones son proyecciones derivadas desde PostgreSQL. Por ejemplo, `product_catalog` combina producto, categoria, ventas y resenas; `customer_profiles` resume comportamiento de clientes; y `geo_analytics` guarda agregados geograficos. La ventaja es que las consultas documentales leen estructuras ya preparadas.

## 8. Query optimizada en MongoDB Atlas

Tiempo sugerido: 1 minuto.

Mostrar: `mongosh`.

Ejecutar:

```powershell
docker compose exec mongo mongosh $ATLAS_URI --apiVersion 1 --username $ATLAS_USER --password $ATLAS_USER_PASS --eval "const dbx=db.getSiblingDB('ecommify_analytics'); const exp=dbx.product_catalog.find({'category.translated_name':'health_beauty'}).hint({'category.translated_name':1}).limit(20).explain('executionStats'); printjson({collection:'product_catalog', index:'category.translated_name_1', nReturned:exp.executionStats.nReturned, totalDocsExamined:exp.executionStats.totalDocsExamined, totalKeysExamined:exp.executionStats.totalKeysExamined, executionTimeMillis:exp.executionStats.executionTimeMillis});"
```

Resultado esperado:

```javascript
{
  collection: 'product_catalog',
  index: 'category.translated_name_1',
  nReturned: 20,
  totalDocsExamined: 20,
  totalKeysExamined: 20,
  executionTimeMillis: 0
}
```

Narracion sugerida:

> Esta consulta valida que Atlas usa el indice de categoria. La metrica mas importante aqui no es solo el tiempo, porque el dataset es pequeno y puede reportar cero milisegundos, sino la relacion entre documentos retornados y documentos examinados. Se devuelven 20 documentos y se examinan 20, lo que indica una consulta eficiente.

## 9. Explicacion de la sincronizacion

Tiempo sugerido: 1 minuto.

Mostrar: archivo `tools/sync_postgres_to_mongo.py` o documento tecnico.

Narracion sugerida:

> La sincronizacion es de una sola via. Supabase/PostgreSQL es la fuente de verdad y MongoDB Atlas contiene documentos derivados. El script `sync_postgres_to_mongo.py` lee tablas y vistas materializadas desde PostgreSQL, transforma los datos y actualiza Atlas usando operaciones `upsert`. Esto significa que si el documento existe se actualiza, y si no existe se crea. Por eso el proceso se puede repetir sin duplicar documentos.

Mostrar este flujo:

```text
Supabase PostgreSQL/PostGIS
        |
        | lectura SQL
        v
tools/sync_postgres_to_mongo.py
        |
        | bulk_write + upsert
        v
MongoDB Atlas
```

Comando demostrativo opcional:

```powershell
docker compose run --rm `
  -e SUPABASE_DATABASE_URL=$SUPABASE_DATABASE_URL `
  -e ATLAS_URI=$ATLAS_URI `
  -e ATLAS_USER=$ATLAS_USER `
  -e ATLAS_USER_PASS=$ATLAS_USER_PASS `
  -e MONGO_DB=ecommify_analytics `
  mongo_sync
```

**Nota:** ejecutar este comando solo si se quiere demostrar la sincronizacion en vivo. Si no, mostrar la evidencia ya documentada para evitar consumir tiempo del video.

## 10. Decisiones tecnicas clave para narrar

Tiempo sugerido: 1 a 2 minutos.

### Decision 1: PostgreSQL/Supabase como fuente de verdad

Narracion:

> Se eligio PostgreSQL en Supabase como fuente de verdad porque el dominio tiene pagos, ordenes, clientes, productos y vendedores con relaciones fuertes. Se requieren ACID, PK, FK, `UNIQUE`, `CHECK`, joins e integridad transaccional.

### Decision 2: MongoDB Atlas como capa documental derivada

Narracion:

> MongoDB Atlas se usa para documentos derivados, no para reemplazar el modelo relacional. Esto permite tener estructuras listas para lectura, como catalogo enriquecido o perfiles de clientes, sin sacrificar la integridad transaccional de PostgreSQL.

### Decision 3: Docker como ambiente reproducible, no como destino final

Narracion:

> Docker se uso para facilitar el trabajo remoto, normalizar el dataset, validar scripts y repetir la carga de forma controlada. La arquitectura final de la actividad es cloud con Supabase y MongoDB Atlas; Docker queda como respaldo reproducible y entorno de pruebas.

### Decision 4 opcional: PostGIS y `pg_trgm`

Narracion:

> PostGIS se incorporo para consultas geograficas reales sobre coordenadas y `pg_trgm` para busquedas textuales aproximadas. Ambas extensiones se validaron en Supabase y se respaldaron con indices concretos.

## 11. Cierre del video

Tiempo sugerido: 30 segundos.

Narracion sugerida:

> En conclusion, la implementacion valida la arquitectura cloud de Ecommify. Supabase aloja el modelo relacional y espacial con datos reales, MongoDB Atlas aloja la capa documental derivada y Docker permite reconstruir el proceso de forma reproducible. Las evidencias muestran carga completa, indices, extensiones, queries optimizadas y sincronizacion controlada entre sistemas.

## Checklist final del video

| Requisito de la guia | Donde se demuestra |
|---|---|
| Conexion a Supabase | Seccion 2 |
| Conexion a MongoDB Atlas | Seccion 6 |
| Navegacion por tablas principales | Seccion 3 |
| Navegacion por colecciones principales | Seccion 7 |
| Queries optimizadas PostgreSQL | Secciones 4 y 5 |
| Queries optimizadas MongoDB | Seccion 8 |
| Decisiones tecnicas clave | Seccion 10 |
| Sincronizacion entre sistemas | Seccion 9 |
