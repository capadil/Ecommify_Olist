# Ecommify Olist

**Grupo 01 - Equipo E16**

- Jorge Andres Ayala Valero - jorgeayva@unisabana.edu.co
- Pablo Andres Melo Garcia - pablomega@unisabana.edu.co
- Camilo Andres Padilla Garcia - camilopaga@unisabana.edu.co

## Resumen

Ecommify Olist es el proyecto final de la asignatura Diseno y Optimizacion de Bases de Datos. El repositorio implementa una arquitectura hibrida para un caso de e-commerce basado en el dataset Olist: Supabase PostgreSQL/PostGIS actua como fuente de verdad transaccional y espacial, mientras MongoDB Atlas aloja una capa documental derivada para lectura y analitica.

Docker se mantiene como ambiente reproducible de preparacion, carga, validacion y pruebas antes de aplicar cambios en cloud. No es el destino arquitectonico final.

## Arquitectura objetivo

```text
Supabase PostgreSQL/PostGIS -> tools/sync_postgres_to_mongo.py -> MongoDB Atlas
```

| Capa | Tecnologia | Responsabilidad |
|---|---|---|
| Relacional / OLTP | Supabase PostgreSQL/PostGIS | Ordenes, pagos, clientes, productos, vendedores, geografia, restricciones e integridad. |
| Documental / analitica | MongoDB Atlas | Catalogo enriquecido, perfiles de clientes, desempeno de vendedores, analitica geografica y resenas enriquecidas. |
| Reproducibilidad | Docker Compose | Carga desde CSV, validacion local, benchmarks y preparacion de artefactos cloud. |

## Resultados principales

| Dimension | Resultado |
|---|---:|
| Tablas finales en Supabase | 9 |
| Tamano final Supabase | 210 MB |
| `customers` / `orders` | 99.441 / 99.441 registros |
| `order_items` / `order_payments` | 112.650 / 103.886 registros |
| `product_catalog` en Atlas | 32.951 documentos |
| `customer_profiles` en Atlas | 99.441 documentos |
| Total documental restaurado en Atlas | 256.417 documentos, 0 fallos |

Mejoras de rendimiento consolidadas:

| Motor | Consulta | Antes | Despues | Mejora |
|---|---|---:|---:|---:|
| PostgreSQL | OLTP por `order_id` | 25,899 ms | 0,043 ms | 99,83% menos tiempo |
| PostgreSQL | PostGIS por radio | 26,105 ms | 0,351 ms | 98,66% menos tiempo |
| MongoDB | `geo_analytics` por estado/ciudad | 20.888 docs | 20 docs | 99,90% menos documentos examinados |
| MongoDB | `product_catalog` por categoria | 353 docs | 20 docs | 94,33% menos documentos examinados |

## Entregables finales

| Entregable | Archivo |
|---|---|
| Informe tecnico integral U6 Etapa 2 | `Ecommify_Database_Design/docs/Informe_Tecnico_Integral_U6_Etapa_2.md` |
| Pruebas de rendimiento consolidadas | `Ecommify_Database_Design/docs/Pruebas_Rendimiento_Consolidadas_U6.md` |
| Implementacion tecnica U5 | `Ecommify_Database_Design/docs/Documento_Tecnico_Implementacion_U5_Actividad_2.md` |
| Evidencia cloud Supabase | `Ecommify_Database_Design/docs/Evidencia_Migracion_Cloud_Supabase.md` |
| Evidencia cloud MongoDB Atlas | `Ecommify_Database_Design/docs/Evidencia_Migracion_Cloud_MongoDB_Atlas.md` |
| Modelo entidad-relacion | `Ecommify_Database_Design/docs/Modelo_Entidad_Relacion.md` |
| Presentacion ejecutiva | `Ecommify_Database_Design/docs/Presentación ejecutiva.pptx` |

## Estructura del repositorio

```text
README.md
raw/
|-- olist_customers_dataset.csv
|-- olist_geolocation_dataset.csv
|-- olist_order_items_dataset.csv
|-- olist_order_payments_dataset.csv
|-- olist_order_reviews_dataset.csv
|-- olist_orders_dataset.csv
|-- olist_products_dataset.csv
|-- olist_sellers_dataset.csv
`-- product_category_name_translation.csv
Ecommify_Database_Design/
|-- README.md
|-- docker/
|   |-- README.md
|   |-- arquitectura_docker.md
|   |-- docker-compose.yml
|   |-- .env.example
|   |-- .gitignore
|   |-- postgres/init/00_run_schema.sh
|   `-- mongo/init/00_init_mongo.js
|-- docs/
|   |-- Informe_Tecnico_Integral_U6_Etapa_2.md
|   |-- Pruebas_Rendimiento_Consolidadas_U6.md
|   |-- Documento_Tecnico_Implementacion_U5_Actividad_2.md
|   |-- Evidencia_Migracion_Cloud_Supabase.md
|   |-- Evidencia_Migracion_Cloud_MongoDB_Atlas.md
|   |-- Modelo_Entidad_Relacion.md
|   |-- modelo_entidad_relacion.mmd
|   |-- Documento_Tecnico_Diseno_Etapa_2.md
|   |-- Documento_Tecnico_Diseno_Etapa_2.pdf
|   |-- Actividad_U3_Etapa_2.md
|   |-- Actividad_U4_Etapa_2.md
|   |-- Guion_Video_Demostracion_U5_Actividad_2.md
|   `-- Presentación ejecutiva.pptx
|-- postgresql/
|   |-- README.md
|   |-- schema/
|   |-- seed_data/
|   |-- queries/
|   |-- cloud/
|   |-- evidencias
|   `-- evidencias.md
|-- mongodb/
|   |-- README.md
|   |-- schema/
|   |-- queries/
|   |-- evidencias
|   `-- evidencias.md
|-- tools/
|   |-- requirements-sync.txt
|   `-- sync_postgres_to_mongo.py
`-- notebooks/
    `-- Data_Exploration_Analysis.ipynb
```

## Como revisar el proyecto

1. Leer `Ecommify_Database_Design/README.md` como fuente de verdad tecnica.
2. Revisar el informe final en `Ecommify_Database_Design/docs/Informe_Tecnico_Integral_U6_Etapa_2.md`.
3. Revisar los resultados de pruebas en `Ecommify_Database_Design/docs/Pruebas_Rendimiento_Consolidadas_U6.md`.
4. Revisar evidencias cloud en los documentos de Supabase y MongoDB Atlas.
5. Para reconstruir el ambiente local de validacion, seguir `Ecommify_Database_Design/docker/README.md`.

## Uso reproducible con Docker

Desde `Ecommify_Database_Design/docker`:

```powershell
copy .env.example .env
docker compose up -d
```

Luego revisar los README tecnicos de cada motor:

- `Ecommify_Database_Design/postgresql/README.md`
- `Ecommify_Database_Design/mongodb/README.md`
- `Ecommify_Database_Design/docker/README.md`

## Notas de seguridad y entrega

- `Ecommify_Database_Design/docker/.env` esta ignorado por Git.
- `Ecommify_Database_Design/docker/.env.example` contiene credenciales locales de ejemplo.
- Las credenciales reales de Supabase y Atlas no deben versionarse.
- Las pruebas de carga concurrente formales quedan documentadas como siguiente mejora; el repositorio contiene benchmarks de consulta y evidencias de rendimiento antes/despues.
