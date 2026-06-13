
## Indice

1. [Portada y resumen ejecutivo](#1-portada-y-resumen-ejecutivo)
2. [Introduccion y alcance](#2-introduccion-y-alcance)
3. [Analisis de requisitos](#3-analisis-de-requisitos)
4. [Diseno conceptual](#4-diseno-conceptual)
5. [Diseno logico en PostgreSQL](#5-diseno-logico-en-postgresql)
6. [Diseno preliminar en MongoDB](#6-diseno-preliminar-en-mongodb)
7. [Decisiones arquitectonicas justificadas](#7-decisiones-arquitectonicas-justificadas)
8. [Estrategia hibrida OLTP/OLAP](#8-estrategia-hibrida-oltpolap)
9. [Unidad 5 - Actividad 2: Implementacion Docker y evidencias](#9-unidad-5---actividad-2-implementacion-docker-y-evidencias)
10. [Anexos tecnicos](#10-anexos-tecnicos)

---

## 1. Portada y resumen ejecutivo

### 1.1 Portada

**Titulo del proyecto:** Ecommify Database Design  
**Base de datos de referencia:** Olist / Ecommify  
**Motor transaccional principal:** PostgreSQL  
**Capa documental / analitica derivada:** MongoDB  
**Integrantes Grupo1:** 
  * Jorge Andres Ayala Valero - jorgeayva@unisabana.edu.co
  * Pablo Andres Melo Garcia - pablomega@unisabana.edu.co
  * Camilo Andres Padilla Garcia - camilopaga@unisabana.edu.co


**Fecha:** 24/05/2026

### 1.2 Resumen ejecutivo

Este documento presenta el diseño conceptual y logico de la base de datos para Ecommify, tomando como punto de partida el analisis exploratorio del dataset Olist. La propuesta adopta una arquitectura hibrida en la que PostgreSQL funciona como fuente principal de verdad para los procesos transaccionales, mientras que MongoDB se utiliza como una capa derivada orientada a lectura, analitica, catalogo enriquecido, perfiles de clientes, desempeno de vendedores, analisis geografico y documentos de resenas.

El modelo relacional conserva las entidades estructurales del negocio: clientes, ordenes, items de orden, pagos, productos, vendedores, categorias, resenas y geolocalizacion. Estas entidades se normalizan hasta 3FN para reducir redundancia, preservar integridad referencial y garantizar consistencia en operaciones criticas. A la vez, se incorporan tipos avanzados de PostgreSQL de forma controlada: `products.specifications JSONB`, `products.photo_urls TEXT[]` y `orders.lifecycle JSONB`. La solucion tambien contempla particionamiento de `orders` por fecha, vistas materializadas para consultas OLAP, triggers de auditoria para `updated_at` y jobs programados de mantenimiento.

---

## 2. Introduccion y alcance

### 2.1 Contexto del proyecto

Ecommify requiere un modelo de datos capaz de soportar operaciones transaccionales de comercio electronico y consultas analiticas derivadas del comportamiento de clientes, productos, vendedores, pagos, resenas y ubicacion geografica. El analisis exploratorio evidencio que el dataset tiene una estructura relacional clara y que las entidades principales presentan relaciones estables, lo cual favorece un modelo normalizado en PostgreSQL.

### 2.2 Objetivo del documento

Definir el diseno conceptual y logico de la base de datos del proyecto, incluyendo:

- Requisitos funcionales y no funcionales.
- Entidades principales y relaciones de negocio.
- Modelo logico normalizado en PostgreSQL.
- Uso justificado de tipos avanzados.
- Diseno preliminar de documentos derivados en MongoDB.
- Decisiones arquitectonicas y trade-offs.
- Estrategia de soporte para cargas OLTP y OLAP.

### 2.3 Alcance de la Etapa 2

La Etapa 2 se enfoca en el diseno conceptual y logico. No reemplaza la implementacion final de scripts DDL, cargas de datos o dashboards, pero deja definidas las decisiones que esos artefactos deben seguir.

---

## 3. Analisis de requisitos

### 3.1 Requisitos funcionales

| Requisito | Descripcion | Decision de diseno |
|---|---|---|
| Gestion de catalogo | Administrar productos, categorias, dimensiones, peso y atributos variables. | `products` y `category_translation` se conservan en PostgreSQL; el catalogo enriquecido se deriva en MongoDB. |
| Gestion transaccional | Registrar ordenes, items de orden, pagos y estados logisticos. | PostgreSQL conserva `orders`, `order_items` y `order_payments` como tablas relacionales con PK, FK y constraints. |
| Gestion de clientes | Mantener clientes, ubicacion basica y relacion con ordenes. | `customers` queda como tabla base; `customer_profiles` se deriva para analitica. |
| Gestion de vendedores | Mantener vendedores y relacionarlos con productos vendidos e items de orden. | `sellers` queda como tabla base; `seller_performance` se deriva para reportes. |
| Gestion de resenas | Registrar calificaciones, comentarios y fechas de feedback. | `order_reviews` se conserva en PostgreSQL y puede derivarse a documentos enriquecidos en MongoDB. |
| Analisis geografico | Analizar comportamiento por ciudad, estado o prefijo postal. | `geolocation` se limpia/consolida en PostgreSQL y `geo_analytics` se deriva en MongoDB. |
| Dashboards analiticos | Consultar ventas, segmentos, desempeno y geografia sin afectar OLTP. | Se proponen vistas materializadas y documentos derivados. |

### 3.2 Requisitos no funcionales

| Requisito | Descripcion | Decision de diseno |
|---|---|---|
| Consistencia | Mantener integridad en ordenes, pagos, clientes, productos y vendedores. | PostgreSQL se define como fuente de verdad ACID. |
| Integridad referencial | Evitar registros huerfanos entre entidades principales. | Uso de PK, FK, `NOT NULL`, `CHECK` e indices. |
| Flexibilidad | Permitir atributos variables en catalogo y documentos enriquecidos. | Uso controlado de `JSONB`, arrays y MongoDB derivado. |
| Escalabilidad | Separar cargas transaccionales y analiticas. | Particionamiento, vistas materializadas, jobs y documentos de lectura. |
| Rendimiento | Evitar consultas analiticas pesadas sobre tablas OLTP. | Materialized views, indices y colecciones derivadas. |
| Trazabilidad | Registrar cambios y mantener fechas operacionales. | `created_at`, `updated_at` y triggers de mantenimiento. |

### 3.3 Restricciones de negocio

| Restriccion | Tabla / campo | Implementacion sugerida |
|---|---|---|
| El precio de item no puede ser negativo. | `order_items.price` | `CHECK (price >= 0)` |
| El valor de flete no puede ser negativo. | `order_items.freight_value` | `CHECK (freight_value >= 0)` |
| El valor de pago no puede ser negativo. | `order_payments.payment_value` | `CHECK (payment_value >= 0)` |
| Un pago se identifica por orden y secuencia. | `order_payments` | `payment_sk` como PK tecnica y `UNIQUE (order_sk, payment_sequential)` |
| Toda orden debe tener fecha de compra. | `orders.order_purchase_timestamp` | `TIMESTAMP NOT NULL` |
| Toda orden debe tener estado. | `orders.order_status` | `NOT NULL` |
| La calificacion debe estar en rango valido. | `order_reviews.review_score` | `CHECK (review_score BETWEEN 1 AND 5)` |
| El producto debe mantener categoria controlada cuando aplique. | `products.product_category_name` | FK hacia `category_translation` o referencia validada |

---

### 3.4 Analisis ACID por modulo

El requisito ACID se aplica de forma diferenciada por modulo. PostgreSQL concentra las operaciones que requieren atomicidad, consistencia, aislamiento y durabilidad; MongoDB queda como capa derivada y no sustituye las garantias transaccionales del nucleo.

| Modulo | Atomicidad | Consistencia | Aislamiento | Durabilidad |
|---|---|---|---|---|
| Ordenes | La creacion o cambio de una orden se confirma como unidad logica. | FK hacia `customers`, fecha de compra obligatoria y estado obligatorio. | Evita leer estados parciales durante cambios operativos. | La orden confirmada queda persistida como evento central del negocio. |
| Items de orden | Los items asociados a una orden se registran completos o se revierten. | FK hacia `orders`, `products` y `sellers`; precio y flete no negativos. | Evita lecturas parciales del detalle de compra. | Los items vendidos quedan disponibles para trazabilidad y analitica. |
| Pagos | Cada pago se registra completo con su secuencia. | FK hacia `orders`, `UNIQUE (order_sk, payment_sequential)` y valor no negativo. | Evita duplicidad o lectura incompleta de pagos concurrentes. | El dato financiero confirmado debe conservarse. |
| Catalogo | Los cambios de producto y categoria se aplican de forma coherente. | FK hacia categorias, dimensiones validadas y uso controlado de `JSONB`/`TEXT[]`. | Evita inconsistencias entre producto maestro y atributos flexibles. | El producto maestro persiste en PostgreSQL como fuente de verdad. |
| Clientes y vendedores | Los datos maestros se actualizan como unidad. | IDs Olist `TEXT UNIQUE`, llaves tecnicas `_sk` y relaciones validas. | Evita referencias huerfanas en ordenes o items. | La trazabilidad de actores se mantiene. |
| Resenas | La resena se registra asociada a una orden existente. | FK hacia `orders` y `CHECK (review_score BETWEEN 1 AND 5)`. | Evita conflictos al actualizar feedback. | El historial de experiencia queda persistido. |
| Geolocalizacion limpia | La consolidacion geografica termina antes de alimentar analitica. | Reglas de limpieza por prefijo, ciudad, estado y coordenadas. | Evita que reportes usen datos parcialmente procesados. | La version limpia queda disponible para analisis posterior. |
| Vistas materializadas | El refresh se publica solo si termina completo. | Se derivan desde tablas fuente validadas. | Separa consultas OLAP de operaciones OLTP. | Los agregados persisten hasta el siguiente refresh. |

## 4. Diseno conceptual

### 4.1 Entidades principales

| Entidad | Descripcion | Rol en el negocio |
|---|---|---|
| Customer | Cliente que realiza una o varias ordenes. | Actor transaccional principal. |
| Order | Pedido realizado por un cliente. | Nucleo del proceso de compra. |
| Order Item | Producto vendido dentro de una orden. | Relaciona orden, producto y vendedor. |
| Payment | Pago asociado a una orden. | Soporta informacion financiera y secuencias de pago. |
| Product | Producto ofrecido en el catalogo. | Entidad base del catalogo. |
| Category | Categoria traducida o normalizada del producto. | Referencia para clasificacion. |
| Seller | Vendedor asociado a items de orden. | Actor comercial de oferta. |
| Review | Resena o calificacion asociada a una orden. | Feedback del cliente. |
| Geolocation | Informacion geografica por prefijo postal, ciudad y estado. | Soporte para analisis geografico. |

### 4.2 Relaciones conceptuales

| Relacion | Cardinalidad | Descripcion |
|---|---|---|
| Customer - Order | 1:N | Un cliente puede realizar varias ordenes; una orden pertenece a un cliente. |
| Order - Order Item | 1:N | Una orden puede contener varios items. |
| Product - Order Item | 1:N | Un producto puede aparecer en multiples items de orden. |
| Seller - Order Item | 1:N | Un vendedor puede vender multiples items. |
| Order - Payment | 1:N | Una orden puede tener uno o varios pagos secuenciales. |
| Order - Review | 1:0..1 | Una orden puede tener una resena asociada. |
| Product - Category | N:1 | Muchos productos pueden pertenecer a una categoria. |
| Customer/Seller - Geolocation | N:1 logica | Clientes y vendedores pueden asociarse por prefijo postal, ciudad o estado. |

### 4.3 Diagrama conceptual

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : "realiza"
    ORDERS ||--|{ ORDER_ITEMS : "contiene"
    PRODUCTS ||--o{ ORDER_ITEMS : "aparece_en"
    SELLERS ||--o{ ORDER_ITEMS : "vende"
    ORDERS ||--o{ ORDER_PAYMENTS : "tiene"
    ORDERS ||--o| ORDER_REVIEWS : "recibe"
    CATEGORY_TRANSLATION ||--o{ PRODUCTS : "clasifica"
    GEOLOCATION ||--o{ CUSTOMERS : "referencia_cliente"
    GEOLOCATION ||--o{ SELLERS : "referencia_vendedor"
```

---

## 5. Diseno logico en PostgreSQL

### 5.1 Decision general

PostgreSQL se define como el motor principal para el modelo transaccional normalizado. Conserva las tablas base de clientes, ordenes, items de orden, pagos, productos, categorias, vendedores, resenas y geolocalizacion. Esta decision se fundamenta en la necesidad de integridad referencial, consistencia, constraints, transacciones ACID y control de claves.

### 5.2 Tablas relacionales principales

| Tabla | Proposito | PK tecnica | Identificador Olist / natural | Observaciones |
|---|---|---|---|---|
| `customers` | Clientes del sistema. | `customer_sk` | `customer_id TEXT UNIQUE` | `customer_id` se conserva para trazabilidad con Olist. |
| `orders` | Ordenes realizadas por clientes. | `order_sk` | `order_id TEXT UNIQUE` | FK interna `customer_sk`; incluye fechas, `order_status`, `lifecycle JSONB`, `created_at`, `updated_at`. |
| `order_items` | Items asociados a ordenes. | `order_item_sk` | `UNIQUE (order_sk, order_item_id)` | Relaciona orden, producto y vendedor mediante llaves internas. |
| `order_payments` | Pagos de una orden. | `payment_sk` | `UNIQUE (order_sk, payment_sequential)` | No mover pagos a `JSONB`; mantener consistencia transaccional. |
| `products` | Producto base del catalogo. | `product_sk` | `product_id TEXT UNIQUE` | Mantener dimensiones como columnas; agregar `specifications JSONB` y `photo_urls TEXT[]`. |
| `category_translation` | Traduccion y normalizacion de categorias. | `category_sk` | `product_category_name TEXT UNIQUE` | Tabla de referencia para catalogo. |
| `sellers` | Vendedores. | `seller_sk` | `seller_id TEXT UNIQUE` | Entidad estructurada transaccional. |
| `order_reviews` | Resenas y calificaciones. | `review_sk` | `UNIQUE (review_id, order_sk)` | Permite trazabilidad sin depender del ID textual como PK fisica. |
| `geolocation_clean` | Datos geograficos limpios o consolidados, con columna espacial PostGIS `geog`. | `geolocation_sk` | Prefijo postal indexado y `geog` indexado con GiST | Se recomienda consolidar duplicados antes de uso analitico. |

### 5.3 Estrategia de llaves tecnicas

El modelo diferencia entre llaves tecnicas internas e identificadores de origen:

| Elemento | Decision | Justificacion |
|---|---|---|
| Llaves primarias | Usar `BIGINT GENERATED ALWAYS AS IDENTITY` con sufijo `_sk`. | Reduce tamano de indices, mejora joins y evita depender de identificadores externos largos. |
| IDs Olist | Mantenerlos como `TEXT UNIQUE`. | Conservan trazabilidad con archivos fuente y busquedas operacionales. |
| Llaves foraneas | Relacionar tablas mediante `customer_sk`, `order_sk`, `product_sk`, `seller_sk`, `category_sk`. | Mantiene integridad referencial eficiente en PostgreSQL. |
| Claves naturales | Usar `UNIQUE` para reglas de negocio. | Por ejemplo, `UNIQUE (order_sk, payment_sequential)` conserva la secuencia de pagos por orden. |
| UUID | No adoptarlo inicialmente. | Los IDs Olist no son UUID generados por el sistema; convertirlos artificialmente no aporta valor al alcance actual. |

### 5.4 Normalizacion

El modelo se normaliza hasta 3FN:

- 1FN: los atributos se mantienen atomicos; las repeticiones se separan en tablas como `order_items` y `order_payments`.
- 2FN: las reglas naturales compuestas se conservan mediante `UNIQUE`, por ejemplo item por orden y pago secuencial por orden.
- 3FN: se separan dependencias transitivas, por ejemplo categorias en `category_translation` y entidades independientes como clientes, vendedores y productos.

### 5.5 Tipos avanzados aprobados

| Tipo | Uso aprobado | Justificacion |
|---|---|---|
| `JSONB` | `products.specifications`, `orders.lifecycle` | Permite flexibilidad controlada sin reemplazar columnas normalizadas. |
| `TEXT[]` | `products.photo_urls` | Representa una lista simple de URLs de imagenes cuando no hay metadata compleja. |
| `hstore` | No usado | Se descarta porque `JSONB` cubre mejor los casos flexibles. |
| Composite type | No usado inicialmente | Se descarta para dimensiones; las dimensiones quedan como columnas simples. |
| Range types | Evaluado, no implementado | Promociones quedan fuera del alcance inicial. |

### 5.5.1 Implementacion de extensiones PostgreSQL

Las extensiones se documentan como capacidades disponibles que se aplican mediante objetos concretos del diseno fisico: columnas, funciones, operadores e indices. Segun la documentacion oficial de PostgreSQL, `CREATE EXTENSION` carga una extension disponible en la base de datos y registra los objetos SQL que esta aporta.

En la version actual del modelo fisico se implementan `pg_trgm` y PostGIS:

| Extension | Implementacion propuesta | Modulo relacionado | Decision |
|---|---|---|---|
| `pg_trgm` | Habilitada en `paso_01_crear_esquema.sql`; aplicada en `paso_03_crear_indices.sql` mediante indices GIN `gin_trgm_ops` sobre ciudades, categorias y texto de resenas. | Catalogo, resenas y soporte analitico. | Adoptada; no cambia entidades ni relaciones. |
| `postgis` | Habilitada en `paso_01_crear_esquema.sql`; agrega `geolocation_clean.geog GEOGRAPHY(Point, 4326)` como columna generada desde coordenadas limpias; crea indice GiST. | Geografia, logistica y `geo_analytics`. | Adoptada; cambia la tabla `geolocation_clean` y se refleja en el ER. |
| `btree_gin` | Evaluar solo para indices GIN compuestos que combinen campos escalares con `JSONB` o arrays. | Catalogo con `specifications JSONB` y `photo_urls TEXT[]`. | Evaluada, no implementada por ahora. |
| `pgcrypto` | Mantener como alternativa para UUID o hashes en integraciones futuras. | Integraciones futuras y auditoria tecnica. | Evaluada, no requerida por la decision de llaves `BIGINT IDENTITY`. |

Impacto aplicado:

| Artefacto | Cambio |
|---|---|
| `postgresql/schema/paso_01_crear_esquema.sql` | Habilita `pg_trgm` y PostGIS. |
| `postgresql/schema/paso_02_crear_tablas_base.sql` | Agrega columna espacial generada `geog` en `geolocation_clean`. |
| `postgresql/schema/paso_03_crear_indices.sql` | Agrega indice GiST para `geog` e indices trigram para busqueda aproximada. |
| ER transaccional | Actualiza `GEOLOCATION_CLEAN` para incluir `geog`. |

Ejemplos implementados:

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE INDEX IF NOT EXISTS idx_customers_city_trgm
ON ecommify.customers USING GIN (customer_city gin_trgm_ops)
WHERE customer_city IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_geolocation_clean_geog_gist
ON ecommify.geolocation_clean USING GIST (geog)
WHERE geog IS NOT NULL;
```

Referencias oficiales consultadas:

- PostgreSQL Documentation - `CREATE EXTENSION`: https://www.postgresql.org/docs/current/sql-createextension.html
- PostgreSQL Documentation - `pg_trgm`: https://www.postgresql.org/docs/current/pgtrgm.html
- PostgreSQL Documentation - `btree_gin`: https://www.postgresql.org/docs/current/btree-gin.html
- PostgreSQL Documentation - `pgcrypto`: https://www.postgresql.org/docs/current/pgcrypto.html
- PostGIS Documentation - Getting Started: https://postgis.net/documentation/getting_started/
### 5.6 Auditoria operacional

Se recomienda agregar `created_at` y `updated_at` en tablas maestras y transaccionales relevantes:

- `customers`
- `orders`
- `order_items`
- `order_payments`
- `products`
- `sellers`
- `order_reviews`

El campo `updated_at` debe mantenerse mediante trigger para evitar depender de actualizaciones manuales desde la aplicacion.

### 5.7 Particionamiento

La tabla `orders` se analiza para particionamiento por rango mensual usando `order_purchase_timestamp`.

Decision:

- El modelo base conserva `orders` no particionada para mantener FKs simples por `order_sk`.
- El particionamiento queda como alternativa fisica documentada, porque PostgreSQL exige que una PK/UNIQUE de tabla particionada incluya la clave de particion.
- MongoDB no reemplaza el particionamiento; solo consume agregados o documentos derivados.

### 5.8 Vistas materializadas

| Vista materializada | Proposito | Tablas origen |
|---|---|---|
| `mv_sales_by_category_monthly` | Ventas mensuales por categoria. | `orders`, `order_items`, `products`, `category_translation` |
| `mv_customer_segments` | Segmentacion de clientes por frecuencia, valor y comportamiento. | `customers`, `orders`, `order_payments`, `order_reviews` |
| `mv_seller_performance_monthly` | Desempeno mensual de vendedores. | `sellers`, `order_items`, `orders`, `order_reviews` |
| `mv_geo_sales_summary` | Ventas agregadas por ciudad o estado. | `orders`, `customers`, `geolocation_clean` |
---

## 6. Diseno preliminar en MongoDB

### 6.1 Decision general

MongoDB no reemplaza las tablas transaccionales de PostgreSQL. Su rol es almacenar documentos derivados, enriquecidos y orientados a lectura. Estos documentos deben reconstruirse o sincronizarse desde PostgreSQL segun jobs de actualizacion definidos.

### 6.2 Colecciones propuestas

| Coleccion | Fuente principal | Uso |
|---|---|---|
| `product_catalog` | `products`, `category_translation`, `order_reviews`, metricas de ventas | Catalogo enriquecido para consulta rapida. |
| `customer_profiles` | `customers`, `orders`, `order_payments`, `order_reviews` | Perfil analitico de clientes. |
| `seller_performance` | `sellers`, `order_items`, `orders`, `order_reviews` | Desempeno comercial de vendedores. |
| `geo_analytics` | `geolocation`, `customers`, `sellers`, `orders` | Analisis geografico agregado. |
| `review_documents` | `order_reviews`, `orders`, `products` | Resenas enriquecidas con contexto de orden y producto. |

### 6.3 Tipos documentales validos

MongoDB debe usar tipos documentales propios como:

- `object`
- `array`
- `string`
- `number`
- `date`
- `boolean`

No se debe declarar `JSONB` como tipo de MongoDB, porque `JSONB` es un tipo especifico de PostgreSQL.

### 6.4 Ejemplo conceptual de `product_catalog`

```json
{
  "product_id": "TEXT",
  "category": {
    "name": "TEXT",
    "translated_name": "TEXT"
  },
  "dimensions": {
    "weight_g": 0,
    "length_cm": 0,
    "height_cm": 0,
    "width_cm": 0
  },
  "specifications": {
    "color": "string",
    "material": "string"
  },
  "photos": ["https://example.com/photo-1.jpg"],
  "sales_metrics": {
    "total_orders": 0,
    "total_revenue": 0
  },
  "review_summary": {
    "avg_score": 0,
    "review_count": 0
  },
  "updated_at": "date"
}
```

---

## 7. Decisiones arquitectonicas justificadas

### 7.1 Matriz PostgreSQL vs MongoDB

| Entidad / elemento | Decision en PostgreSQL | Decision en MongoDB | Justificacion |
|---|---|---|---|
| `customers` | Tabla base normalizada. | Resumen derivado en `customer_profiles`. | PostgreSQL conserva integridad; MongoDB consolida comportamiento. |
| `orders` | Tabla transaccional principal, particionada por fecha. | Timeline o resumen derivado. | Las ordenes requieren consistencia y trazabilidad. |
| `order_items` | Tabla relacional. | Agregados de ventas. | Es relacion central entre orden, producto y vendedor. |
| `order_payments` | Tabla relacional con PK compuesta. | Solo resumen derivado. | Pagos requieren consistencia y validacion estricta. |
| `products` | Producto base con columnas normalizadas y tipos avanzados aprobados. | `product_catalog`. | PostgreSQL conserva el maestro; MongoDB enriquece lectura. |
| `category_translation` | Tabla de referencia. | Campo derivado en catalogo. | Referencia estable para normalizacion. |
| `sellers` | Tabla base. | `seller_performance`. | MongoDB consolida metricas derivadas. |
| `order_reviews` | Tabla asociada a ordenes. | Documentos enriquecidos. | Texto libre y campos opcionales favorecen documentos de lectura. |
| `geolocation` | Tabla limpia/consolidada. | `geo_analytics`. | Analisis geografico se beneficia de agregacion. |

### 7.2 Decision sobre IDs y llaves tecnicas

Se recomienda conservar los IDs originales de Olist como identificadores externos `TEXT UNIQUE`:

- `order_id`
- `customer_id`
- `product_id`
- `seller_id`
- `review_id`

Sin embargo, no se usan como claves primarias fisicas. El modelo incorpora llaves tecnicas internas tipo `BIGINT GENERATED ALWAYS AS IDENTITY`, por ejemplo `order_sk`, `customer_sk`, `product_sk` y `seller_sk`. Las FK internas apuntan a estas llaves tecnicas.

No se adopta `uuid-ossp` como decision inicial. Si se menciona, debe quedar como alternativa evaluada o futura, no como requisito del modelo base.

### 7.3 Trade-offs

| Decision | Ventaja | Costo / riesgo | Mitigacion |
|---|---|---|---|
| PostgreSQL como fuente de verdad | Integridad, ACID, constraints, FK. | Consultas analiticas pueden ser pesadas. | Vistas materializadas, indices y particiones. |
| MongoDB como capa derivada | Lectura flexible y documentos enriquecidos. | Riesgo de inconsistencia si no se sincroniza bien. | Jobs de refresh y definicion de fuente principal. |
| Uso de `JSONB` controlado | Flexibilidad para atributos variables. | Puede ocultar datos que deberian ser columnas. | Usarlo solo en `specifications` y `lifecycle`. |
| Dimensiones como columnas | Consultas y validaciones simples. | Menos flexible para estructuras anidadas. | Replicar como subdocumento solo en MongoDB. |
| Materialized views | Mejor rendimiento OLAP. | Datos no siempre en tiempo real. | Definir frecuencia de refresh. |

### 7.4 Consideraciones CAP

PostgreSQL prioriza consistencia para las operaciones transaccionales. MongoDB se usa como capa derivada de lectura, por lo que puede tolerar consistencia eventual en documentos analiticos. Esta separacion evita que la capa documental comprometa operaciones criticas como pagos, ordenes e integridad del catalogo base.

Criterios aplicados:

- Criticidad transaccional del dato.
- Tolerancia a desfase entre fuente y lectura.
- Necesidad de disponibilidad para consultas analiticas.
- Definicion explicita de fuente de verdad.

| Modulo / estructura | Base principal | Prioridad CAP | Criterio explicito |
|---|---|---|---|
| Ordenes | PostgreSQL | Consistencia sobre disponibilidad ante particion | No se deben confirmar ordenes incompletas ni estados contradictorios. |
| Items de orden | PostgreSQL | Consistencia | La relacion orden-producto-vendedor requiere FK y restricciones validas. |
| Pagos | PostgreSQL | Consistencia estricta | El dato financiero no tolera duplicidad, perdida de secuencia ni valores invalidos. |
| Clientes y vendedores | PostgreSQL | Consistencia | Son datos maestros relacionados con transacciones; no deben generar registros huerfanos. |
| Catalogo base | PostgreSQL | Consistencia | El producto maestro, categoria y dimensiones deben conservar reglas relacionales. |
| Resenas base | PostgreSQL | Consistencia en la fuente | La resena oficial se asocia a una orden valida; los documentos derivados pueden retrasarse. |
| `product_catalog` | MongoDB derivado | Disponibilidad con consistencia eventual | Es una vista enriquecida de lectura; se reconstruye o refresca desde PostgreSQL. |
| `customer_profiles` | MongoDB derivado | Disponibilidad con consistencia eventual | El perfil analitico puede tener desfase mientras no afecte operaciones OLTP. |
| `seller_performance` | MongoDB derivado | Disponibilidad con consistencia eventual | Los indicadores de desempeno pueden recalcularse por lotes. |
| `geo_analytics` | MongoDB derivado / vistas OLAP | Disponibilidad analitica con consistencia eventual | El analisis geografico tolera refresh programado despues de limpiar `geolocation`. |
| Vistas materializadas | PostgreSQL OLAP | Consistencia derivada con desfase controlado | Los datos son consistentes con el ultimo refresh, no necesariamente en tiempo real. |

---

## 8. Estrategia hibrida OLTP/OLAP

### 8.1 Separacion de cargas

| Tipo de carga | Necesidad | Solucion propuesta |
|---|---|---|
| OLTP | Registrar ordenes, items, pagos y cambios operativos. | PostgreSQL normalizado con constraints, FK, indices y triggers. |
| OLAP | Consultar ventas, clientes, vendedores, categorias y geografia. | Vistas materializadas y MongoDB derivado. |

### 8.2 Jobs programados

| Job | Frecuencia sugerida | Objetivo |
|---|---|---|
| `VACUUM/ANALYZE` | Diario | Mantener estadisticas y salud de tablas. |
| Refresh de vistas materializadas | Semanal o segun necesidad | Actualizar dashboards y metricas. |
| Creacion de particiones | Mensual | Preparar nuevas particiones de `orders`. |
| Revision de indices | Mensual | Validar indices usados/no usados. |
| Sincronizacion MongoDB | Segun SLA analitico | Actualizar documentos derivados. |

### 8.3 Metricas de monitoreo

| Capa | Metrica | Uso |
|---|---|---|
| OLTP | Tiempo de insercion/actualizacion de ordenes | Medir rendimiento transaccional. |
| OLTP | Bloqueos y deadlocks | Detectar problemas de concurrencia. |
| OLTP | Crecimiento de particiones | Planificar almacenamiento. |
| OLAP | Tiempo de refresh de vistas materializadas | Controlar costo analitico. |
| OLAP | Tiempo de respuesta de dashboards | Validar experiencia de consulta. |
| MongoDB | Tamano y fecha de actualizacion de documentos | Controlar vigencia de datos derivados. |

---

## 9. Unidad 5 - Actividad 2: Implementacion Docker y evidencias

### 9.1 Objetivo de implementacion

La Unidad 5 - Actividad 2 tiene como objetivo ejecutar localmente la arquitectura definida para Ecommify usando Docker Compose. Esta implementacion no cambia las decisiones del diseno: PostgreSQL permanece como fuente de verdad transaccional y MongoDB funciona como capa documental derivada para lectura y analitica.

La implementacion permite validar cinco aspectos:

- Levantamiento reproducible de servicios Docker.
- Carga del dataset real Olist en PostgreSQL.
- Refresco de vistas materializadas para analitica.
- Sincronizacion PostgreSQL -> MongoDB.
- Generacion de evidencias tecnicas y academicas.

### 9.2 Artefactos de ejecucion

| Archivo | Funcion |
|---|---|
| `docker/docker-compose.yml` | Define servicios, volumenes, puertos, healthchecks y montajes. |
| `docker/README.md` | Documenta comandos de ejecucion y validacion. |
| `docker/arquitectura_docker.md` | Presenta diagramas de creacion, migracion y comunicacion final. |
| `postgresql/seed_data/` | Contiene scripts de staging, carga CSV, insercion final y validacion. |
| `tools/sync_postgres_to_mongo.py` | Sincroniza documentos derivados hacia MongoDB. |
| `postgresql/evidencias.md` | Interpreta evidencias PostgreSQL. |
| `mongodb/evidencias.md` | Interpreta evidencias MongoDB. |

### 9.3 Secuencia ejecutada

| Orden | Paso | Resultado esperado |
|---|---|---|
| 1 | Levantar Docker con `docker compose up -d` | PostgreSQL y MongoDB activos y saludables. |
| 2 | Crear staging PostgreSQL | Tablas temporales listas para CSV. |
| 3 | Cargar CSV Olist | Datos crudos disponibles en staging. |
| 4 | Insertar modelo final | Tablas normalizadas cargadas con llaves tecnicas. |
| 5 | Validar carga | Conteos finales y `geog` poblado. |
| 6 | Refrescar vistas materializadas | Vistas OLAP disponibles para consultas. |
| 7 | Ejecutar validadores MongoDB | Colecciones e indices listos. |
| 8 | Ejecutar `mongo_sync` | Documentos derivados cargados mediante `upsert`. |
| 9 | Ejecutar consultas MongoDB | Evidencia de lectura analitica documental. |

### 9.4 Evidencias generadas

| Evidencia | Archivo | Validacion |
|---|---|---|
| PostgreSQL academica | `postgresql/evidencias.md` | PostGIS, `pg_trgm`, indices OLTP y vistas materializadas. |
| PostgreSQL cruda | `postgresql/evidencias` | Salida original de consola. |
| MongoDB academica | `mongodb/evidencias.md` | Indices, conteos, sincronizacion y consultas analiticas. |
| MongoDB cruda | `mongodb/evidencias` | Salida original de consola. |

### 9.5 Resultados validados

| Componente | Resultado |
|---|---|
| PostgreSQL tablas finales | `customers`: 99.441; `orders`: 99.441; `order_items`: 112.650; `order_payments`: 103.886; `order_reviews`: 99.224; `products`: 32.951; `sellers`: 3.095; `category_translation`: 71; `geolocation_clean`: 27.912 |
| PostGIS | `geolocation_clean.geog` con 27.912 registros y uso de indice GiST. |
| Vistas materializadas | `mv_sales_by_category_monthly`: 1.274; `mv_customer_segments`: 99.441; `mv_seller_performance_monthly`: 16.441; `mv_geo_sales_summary`: 21.698 |
| MongoDB colecciones | `product_catalog`: 32.951; `customer_profiles`: 99.441; `seller_performance`: 3.095; `geo_analytics`: 21.698; `review_documents`: 99.224 |

### 9.6 Decisiones tecnicas validadas

| Decision | Evidencia |
|---|---|
| PostgreSQL como fuente de verdad | Carga completa del modelo final con constraints, FK e indices. |
| Separacion OLTP/OLAP | Vistas materializadas refrescadas y colecciones derivadas en MongoDB. |
| PostGIS | Consulta espacial `ST_DWithin` usando indice GiST. |
| `pg_trgm` | Busquedas aproximadas usando indices `gin_trgm_ops`. |
| MongoDB como capa derivada | Colecciones pobladas desde PostgreSQL mediante sincronizador. |
| Sincronizacion idempotente | Uso de `upsert` para evitar duplicados. |
| Ajuste por datos reales | `review_documents` usa indice compuesto `{ review_id: 1, order_id: 1 }`. |

---

## 10. Anexos tecnicos

### 10.1 Diccionario de datos

El diccionario de datos debe incluir, como minimo:

- Nombre de tabla o coleccion.
- Campo.
- Tipo de dato.
- Nulabilidad.
- Clave primaria o foranea.
- Restricciones.
- Descripcion funcional.
- Origen del dato.

### 10.2 Scripts SQL preliminares

Los scripts SQL deben estar alineados con estas decisiones:

- Mantener IDs Olist como `TEXT UNIQUE` para trazabilidad.
- Crear PK tecnicas `BIGINT IDENTITY` y FK internas mediante columnas `*_sk`.
- Agregar restricciones `CHECK` y `UNIQUE` para claves naturales como `(order_sk, payment_sequential)`.
- Agregar `products.specifications JSONB`.
- Agregar `products.photo_urls TEXT[]`.
- Agregar `orders.lifecycle JSONB`.
- Agregar `created_at` y `updated_at`.
- Crear trigger de mantenimiento de `updated_at`.
- Definir particionamiento de `orders`.
- Crear vistas materializadas.

### 10.3 Esquemas MongoDB preliminares

Los esquemas MongoDB deben:

- Usar tipos documentales validos.
- Evitar `JSONB`.
- Indicar fuente relacional de cada campo.
- Aclarar frecuencia de actualizacion.
- Marcar cada coleccion como derivada/no fuente de verdad.

### 10.4 Consultas de ejemplo

Se recomiendan ejemplos de:

- Consulta de orden con items y pagos en PostgreSQL.
- Consulta de ventas mensuales por categoria usando materialized view.
- Consulta de catalogo enriquecido en MongoDB.
- Consulta de perfil de cliente en MongoDB.
- Consulta de desempeno de vendedor.

