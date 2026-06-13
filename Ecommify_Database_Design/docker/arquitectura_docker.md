# Arquitectura Docker local

Este archivo complementa `docker/README.md` con tres vistas del ambiente local: creacion inicial, migracion de datos y comunicacion final. La fuente de verdad de decisiones tecnicas sigue siendo el `README.md` principal del repositorio.

## 1. Creacion del ambiente

Este diagrama muestra que ocurre cuando se ejecuta `docker compose up -d` por primera vez. Docker crea los contenedores, monta carpetas del repositorio y ejecuta scripts de inicializacion cuando los volumenes estan vacios.

```mermaid
flowchart TD
    USER[Usuario ejecuta docker compose up -d]
    COMPOSE[Docker Compose lee docker-compose.yml y .env]

    PG[Contenedor postgres]
    MG[Contenedor mongo]

    PGVOL[(Volumen ecommify_pgdata)]
    MGVOL[(Volumen ecommify_mongodata)]

    PGSCHEMA[postgresql schema]
    PGSEED[postgresql seed_data]
    RAW[raw CSV Olist]
    MGSCHEMA[mongodb schema]

    PGINIT[postgres init ejecuta pasos 01 a 05]
    MGINIT[mongo init ejecuta paso 09]

    USER --> COMPOSE
    COMPOSE --> PG
    COMPOSE --> MG

    PG --> PGVOL
    MG --> MGVOL

    PGSCHEMA --> PG
    PGSEED --> PG
    RAW --> PG
    MGSCHEMA --> MG

    PG --> PGINIT
    MG --> MGINIT

    PGINIT --> PGREADY[PostgreSQL listo con esquema e indices]
    MGINIT --> MGREADY[MongoDB listo con colecciones e indices]
```

## 2. Migracion y sincronizacion de datos

Este diagrama muestra el flujo ejecutado despues de crear el ambiente. Primero se cargan los CSV en PostgreSQL, luego se insertan en el modelo final, se refrescan vistas materializadas y finalmente `mongo_sync` construye documentos derivados en MongoDB.

```mermaid
flowchart LR
    RAW[CSV Olist en raw]
    STAGING[Tablas staging PostgreSQL]
    OLTP[Modelo final PostgreSQL]
    MV[Vistas materializadas PostgreSQL]
    SYNC[mongo_sync Python temporal]
    MONGO[MongoDB ecommify_analytics]

    RAW -->|COPY paso 07| STAGING
    STAGING -->|INSERT SELECT paso 08| OLTP
    OLTP -->|REFRESH paso 07 queries| MV

    OLTP -->|lectura transaccional| SYNC
    MV -->|lectura analitica| SYNC
    SYNC -->|upsert documentos| MONGO

    MONGO --> PC[product_catalog]
    MONGO --> CP[customer_profiles]
    MONGO --> SP[seller_performance]
    MONGO --> GA[geo_analytics]
    MONGO --> RD[review_documents]
```

## 3. Comunicacion final del ambiente

Este diagrama muestra el estado final limpio despues de crear estructuras, cargar PostgreSQL y sincronizar MongoDB. En esta vista ya no se representan scripts de inicializacion, archivos CSV ni montajes de soporte, porque su funcion pertenece a los pasos de creacion y migracion.

```mermaid
flowchart LR
    DEV[Usuario PowerShell]

    subgraph COMPOSE[Docker Compose activo]
        POSTGRES[PostgreSQL ecommify_db]
        MONGO[MongoDB ecommify_analytics]
        PGDATA[(ecommify_pgdata)]
        MONGODATA[(ecommify_mongodata)]
    end

    POSTGRES -->|tablas OLTP indices vistas| PGDATA
    MONGO -->|colecciones indices documentos| MONGODATA

    POSTGRES -. datos derivados sincronizados .-> MONGO

    DEV -->|psql puerto 5432| POSTGRES
    DEV -->|mongosh puerto 27017| MONGO
```
