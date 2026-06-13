# Docker local - Ecommify Database Design

Este directorio contiene el ambiente local reproducible para la Actividad U5 Etapa 2.

La fuente de verdad del diseno sigue siendo el `README.md` principal del repositorio. Docker solo automatiza la ejecucion local de las decisiones ya definidas.

## Que levanta Docker

| Servicio | Imagen | Proposito |
|---|---|---|
| `postgres` | `postgis/postgis:16-3.4` | PostgreSQL 16 con PostGIS disponible para el modelo OLTP y geografia. |
| `mongo` | `mongo:7` | MongoDB local para colecciones analiticas derivadas. |

## Que ocurre al iniciar por primera vez

Docker crea volumenes persistentes y ejecuta scripts de inicializacion solo cuando el volumen esta vacio.

PostgreSQL ejecuta automaticamente:

1. `postgresql/schema/paso_01_crear_esquema.sql`
2. `postgresql/schema/paso_02_crear_tablas_base.sql`
3. `postgresql/schema/paso_03_crear_indices.sql`
4. `postgresql/schema/paso_04_crear_triggers_updated_at.sql`
5. `postgresql/schema/paso_05_crear_vistas_materializadas.sql`

MongoDB ejecuta automaticamente:

1. `mongodb/schema/paso_09_crear_colecciones_validadores.js`

## Comandos basicos

Desde la carpeta `docker/`:

```powershell
cd docker
copy .env.example .env
docker compose up -d
```

Ver contenedores:

```powershell
docker compose ps
```

Ver logs de PostgreSQL:

```powershell
docker compose logs postgres
```

Ver logs de MongoDB:

```powershell
docker compose logs mongo
```

Apagar sin borrar datos:

```powershell
docker compose down
```

Apagar y borrar volumenes para reinicializar desde cero:

```powershell
docker compose down -v
```

## Validaciones PostgreSQL

Entrar a PostgreSQL:

```powershell
docker compose exec postgres psql -U ecommify_user -d ecommify_db
```

Validar extensiones:

```sql
SELECT extname
FROM pg_extension
WHERE extname IN ('postgis', 'pg_trgm');
```

Validar tabla espacial:

```sql
SELECT column_name, udt_name
FROM information_schema.columns
WHERE table_schema = 'ecommify'
  AND table_name = 'geolocation_clean'
  AND column_name = 'geog';
```

Validar indices clave:

```sql
SELECT indexname
FROM pg_indexes
WHERE schemaname = 'ecommify'
  AND indexname IN ('idx_geolocation_clean_geog_gist', 'idx_customers_city_trgm');
```

## Validaciones MongoDB

Entrar a MongoDB:

```powershell
docker compose exec mongo mongosh -u ecommify_admin -p ecommify_password --authenticationDatabase admin
```

Validar base y colecciones:

```javascript
use ecommify_analytics
show collections
db.product_catalog.getIndexes()
```

## Nota importante sobre datos

Este primer ambiente crea estructuras, extensiones, validadores e indices. La carga del dataset Olist y la sincronizacion PostgreSQL -> MongoDB son pasos posteriores de la actividad.