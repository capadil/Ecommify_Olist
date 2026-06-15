# Ecommify_Olist
**Integrantes Grupo01 - Equipo E16:** 
  * Jorge Andres Ayala Valero - jorgeayva@unisabana.edu.co
  * Pablo Andres Melo Garcia - pablomega@unisabana.edu.co
  * Camilo Andres Padilla Garcia - camilopaga@unisabana.edu.co
  
Proyecto de práctica para diseño y análisis de datos usando el dataset Olist. Este repositorio agrupa esquemas, consultas, notebooks y datos crudos usados en la asignatura Diseño y Optimización de Bases de Datos.

## Estructura del repositorio

La estructura principal del proyecto es la siguiente:

```
README.md
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
|-- tools/
|   |-- requirements-sync.txt
|   `-- sync_postgres_to_mongo.py
|-- docs/
|   |-- Actividad_U3_Etapa_2.md
|   |-- Actividad_U4_Etapa_2.md
|   |-- Documento_Tecnico_Diseno_Etapa_2.md
|   |-- Documento_Tecnico_Implementacion_U5_Actividad_2.md
|   |-- Evidencia_Migracion_Cloud_Supabase.md
|   |-- Evidencia_Migracion_Cloud_MongoDB_Atlas.md
|   |-- Documento_Tecnico_Diseno_Etapa_2.pdf
|   |-- Modelo_Entidad_Relacion.md
|   |-- modelo_entidad_relacion.mmd
|   |-- pdf-style.css
|   `-- Presentacion ejecutiva.pptx
|-- postgresql/
|   |-- README.md
|   |-- cloud/
|   |   |-- cloud_supabase_schema.sql
|   |   |-- cloud_supabase_schema_clean.sql
|   |   |-- cloud_supabase_schema_supabase.sql
|   |   `-- cloud_supabase_data_bloque_01_catalogo.sql
|   |-- schema/
|   |   |-- paso_01_crear_esquema.sql
|   |   |-- paso_02_crear_tablas_base.sql
|   |   |-- paso_03_crear_indices.sql
|   |   |-- paso_04_crear_triggers_updated_at.sql
|   |   |-- paso_05_crear_vistas_materializadas.sql
|   |   `-- paso_06_borrador_particionamiento_orders.sql
|   |-- queries/
|   |   |-- paso_07_refrescar_vistas_materializadas.sql
|   |   |-- paso_08_consultas_analiticas_ejemplo.sql
|   |   `-- paso_09_benchmark_antes_despues_indices.sql
|   |-- evidencias
|   |-- evidencias.md
|   `-- seed_data/
|       |-- paso_06_crear_staging.sql
|       |-- paso_07_cargar_csv_staging.sql
|       |-- paso_08_insertar_modelo_final.sql
|       `-- paso_09_validar_carga.sql
|-- mongodb/
|   |-- README.md
|   |-- schema/
|   |   |-- README.md
|   |   `-- paso_09_crear_colecciones_validadores.js
|   |-- queries/
|   |   |-- README.md
|   |   `-- paso_10_consultas_analiticas_ejemplo.js
|   `-- seed_data/
|       `-- README.md
`-- notebooks/
    `-- Data_Exploration_Analysis.ipynb
```

## Contenido y propósito de las carpetas

- **Ecommify_Database_Design/**: Documentación y artefactos para el diseño de la base de datos (diagramas, esquemas y consultas). Ver [Ecommify_Database_Design/](Ecommify_Database_Design).
- **notebooks/**: Análisis exploratorio y notebooks reproducibles. Ver [notebooks/](notebooks) y en particular [notebooks/Data_Exploration_Analysis.ipynb](notebooks/Data_Exploration_Analysis.ipynb).
- **raw/**: Datos crudos CSV originales provistos por Olist. Archivos de interés:
	- [raw/olist_orders_dataset.csv](raw/olist_orders_dataset.csv)
	- [raw/olist_order_items_dataset.csv](raw/olist_order_items_dataset.csv)
	- [raw/olist_products_dataset.csv](raw/olist_products_dataset.csv)
	- [raw/olist_customers_dataset.csv](raw/olist_customers_dataset.csv)

## Cómo usar

1. Explorar los datos abriendo el notebook: [notebooks/Data_Exploration_Analysis.ipynb](notebooks/Data_Exploration_Analysis.ipynb).
2. Revisar el diseño y las consultas en: [Ecommify_Database_Design/](Ecommify_Database_Design).
3. Para cargar los CSV en PostgreSQL o MongoDB, use los scripts y esquemas dentro de las carpetas `Ecommify_Database_Design/mongodb` o `notebooks/postgresql` según la guía del proyecto.

