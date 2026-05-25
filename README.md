# Ecommify_Olist
**Integrantes Grupo1:** 
  * Jorge Andres Ayala Valero - jorgeayva@unisabana.edu.co
  * Pablo Andres Melo Garcia - pablomega@unisabana.edu.co
  * Camilo Andres Padilla Garcia - camilopaga@unisabana.edu.co
  
Proyecto de práctica para diseño y análisis de datos usando el dataset Olist. Este repositorio agrupa esquemas, consultas, notebooks y datos crudos usados en la asignatura Diseño y Optimización de Bases de Datos.

## Estructura del repositorio

La estructura principal del proyecto es la siguiente:

```
README.md
Ecommify_Database_Design/
		README.md
		docs/
				Documento_Tecnico_Diseno_Etapa_2.md
		mongodb/
				queries/
				schema/
				seed_data/
notebooks/
		Data_Exploration_Analysis.ipynb
		postgresql/
raw/
		olist_customers_dataset.csv
		olist_geolocation_dataset.csv
		olist_order_items_dataset.csv
		olist_order_payments_dataset.csv
		olist_order_reviews_dataset.csv
		olist_orders_dataset.csv
		olist_products_dataset.csv
		olist_sellers_dataset.csv
		product_category_name_translation.csv
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

## Notas

- Este README resume la estructura del repositorio. Si quieres, puedo:
	- Añadir instrucciones de instalación y comandos concretos para cargar datos en PostgreSQL/MongoDB.
	- Crear README específicos para subcarpetas (por ejemplo `Ecommify_Database_Design/README.md`).

---
Actualizado automáticamente para reflejar la estructura del proyecto.