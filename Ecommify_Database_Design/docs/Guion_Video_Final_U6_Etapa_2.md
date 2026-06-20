# Guion del video final — Ecommify Olist (Unidad 6, Etapa 2)

**Duracion objetivo:** 12 a 15 minutos
**Grupo 01 — Equipo E16:** Jorge Andres Ayala · Pablo Andres Melo · Camilo Andres Padilla
**Repositorio:** https://github.com/capadil/Ecommify_Olist

> Nota de produccion: este guion asume que cada integrante graba uno o dos bloques. Los tiempos son acumulados. La columna "En pantalla" indica que mostrar (slide de la presentacion ejecutiva, terminal, Supabase, Atlas o el repositorio). Apoyarse en `Presentacion_Ejecutiva_U6_Etapa_2.pptx` como hilo visual.

---

## Distribucion de bloques y tiempos

| Bloque | Tema | Duracion | Acumulado | Responsable sugerido |
|---|---|---|---|---|
| 1 | Introduccion del equipo y proyecto | 1:00 | 1:00 | Integrante A |
| 2 | Contexto y objetivos | 1:30 | 2:30 | Integrante A |
| 3 | Arquitectura hibrida y justificaciones | 2:30 | 5:00 | Integrante B |
| 4 | Demo en vivo de funcionalidades clave | 4:00 | 9:00 | Integrante B / C |
| 5 | Resultados de evaluacion y analisis comparativo | 2:30 | 11:30 | Integrante C |
| 6 | Lecciones aprendidas y recomendaciones | 1:30 | 13:00 | Integrante A |
| 7 | Conclusiones y cierre | 1:00 | 14:00 | Todos |

Margen de seguridad: ~1 minuto. Objetivo de corte final entre 12:30 y 14:30.

---

## Bloque 1 — Introduccion (0:00 - 1:00)

**En pantalla:** Slide 1 (titulo).

> "Hola, somos el Equipo E16. Presentamos Ecommify, el proyecto final del curso de Diseno y Optimizacion de Bases de Datos. Ecommify es una plataforma de e-commerce construida sobre el dataset publico de Olist, con mas de cien mil ordenes reales. Nuestra propuesta es una arquitectura hibrida: PostgreSQL con PostGIS como fuente de verdad transaccional, y MongoDB Atlas como capa documental derivada para lectura y analitica. En los proximos minutos mostramos el diseno, la implementacion, una demo en vivo y la evaluacion de rendimiento que respalda cada decision."

Presentar brevemente quien habla en cada bloque.

---

## Bloque 2 — Contexto y objetivos (1:00 - 2:30)

**En pantalla:** Slide 2 (contexto y objetivos).

> "El negocio enfrenta dos cargas de trabajo en tension. Por un lado, las operaciones transaccionales —ordenes, pagos e inventario— exigen consistencia fuerte e integridad referencial: cero tolerancia a registros huerfanos. Por otro lado, la capa de lectura —catalogo, perfiles, dashboards y resenas— necesita baja latencia y tolera cierto desfase temporal."

> "Una sola tecnologia no resuelve ambos mundos con la misma eficiencia. Por eso nuestros objetivos fueron: disenar una arquitectura justificada por requisitos, optimizar consultas con indices y agregaciones, evaluar el rendimiento con evidencia empirica, comparar PostgreSQL contra MongoDB en el caso real, y documentar cada decision bajo el Teorema CAP."

---

## Bloque 3 — Arquitectura hibrida y justificaciones (2:30 - 5:00)

**En pantalla:** Slide 3 (diagrama de arquitectura), luego Slides 4 y 5.

> "Esta es la arquitectura objetivo. Supabase aloja PostgreSQL y PostGIS como nucleo relacional y espacial: gobierna integridad, pagos, estados de orden y geografia. MongoDB Atlas aloja documentos derivados para catalogo, perfiles, desempeno de vendedores, analitica geografica y resenas. Entre ambos no hay conexion directa: un job externo en Python lee PostgreSQL y escribe en Atlas con operaciones idempotentes. Docker se mantiene solo como ambiente de reproduccion y pruebas, no como destino productivo."

**Cambiar a Slide 4 (matriz de decision):**

> "La regla de asignacion es clara: todo lo que requiere consistencia fuerte e integridad vive en PostgreSQL; todo lo que es lectura enriquecida o agregada vive en MongoDB como copia reconstruible."

**Cambiar a Slide 5 (decisiones no obvias):**

> "Destacamos cuatro decisiones tecnicas no triviales. Primero, usamos llaves surrogate BIGINT IDENTITY en lugar de los IDs de texto de Olist como llave primaria, conservando esos IDs como TEXT UNIQUE para trazabilidad. Segundo, el particionamiento de ordenes se documento pero se difirio, porque PostgreSQL obliga a incluir la clave de particion en cada indice unico y eso rompia las llaves foraneas con el volumen actual. Tercero, en review_documents descubrimos que usar solo review_id como unico reducia la carga a 994 documentos; el indice compuesto review_id mas order_id nos permitio cargar los 99.224 reales. Y cuarto, aprovechamos extensiones especializadas: pg_trgm para texto aproximado y PostGIS para geografia."

---

## Bloque 4 — Demo en vivo (5:00 - 9:00)

**En pantalla:** alternar entre la consola de Supabase y la de MongoDB Atlas. Tener las consultas preparadas y probadas antes de grabar, y las dos pestanas del navegador ya abiertas y con sesion iniciada.

### Preparacion antes de grabar (no se graba)

1. Abrir el navegador con **dos pestanas**: una en `https://supabase.com/dashboard` y otra en `https://cloud.mongodb.com`.
2. Iniciar sesion en ambas con la cuenta del proyecto.
3. Aumentar el zoom de la pagina a 110-125% (Ctrl con +) para que el texto se lea en el video.
4. Tener a la mano el archivo `postgresql/queries/paso_09_benchmark_antes_despues_indices.sql` y `mongodb/queries/paso_11_benchmark_antes_despues_indices.js` para copiar/pegar las consultas.

### Parte A — Supabase / PostgreSQL (2:00)

**Paso A1 — Mostrar las tablas y conteos (0:30)**
- Ruta: en la pestana de Supabase, clic en el **proyecto Ecommify** en el dashboard.
- En la **barra lateral izquierda**, clic en el icono **"Table Editor"** (icono de cuadricula/tabla).
- En el panel de la izquierda aparece la lista de las **9 tablas** (`customers`, `orders`, `order_items`, `order_payments`, `order_reviews`, `products`, `sellers`, `category_translation`, `geolocation_clean`). Clic en `orders` para mostrar filas reales.
- Narrar: *"Estos son datos reales de Olist ya normalizados en Supabase: 9 tablas, mas de cien mil ordenes."*
- (Opcional para conteos exactos) clic en **"SQL Editor"** en la barra lateral → **"+ New query"** → pegar `SELECT count(*) FROM orders;` → boton **"Run"** (o Ctrl+Enter).

**Paso A2 — Consulta OLTP por order_id con EXPLAIN ANALYZE (0:45)**
- Ruta: barra lateral → **"SQL Editor"** → **"+ New query"**.
- Pegar la consulta OLTP con `EXPLAIN (ANALYZE, BUFFERS)` (esta en el script `paso_09_benchmark...sql`). Clic en **"Run"**.
- Senalar en el plan la linea **`Index Scan using idx_orders_order_id`** y el **`Execution Time`** al final.
- Narrar: *"Con el indice sobre order_id y las FK internas, la busqueda puntual resuelve en fracciones de milisegundo y hace join con pagos e items por llave."*

**Paso A3 — Busqueda espacial PostGIS (0:30)**
- Ruta: misma **"SQL Editor"**, **"+ New query"**, pegar la consulta de radio con `ST_DWithin(...)`. Clic en **"Run"**.
- Narrar: *"PostGIS con indice GiST encuentra ubicaciones dentro de un radio; es el tipo de consulta que solo el motor relacional resuelve bien."*
- (Opcional) mostrar que la extension existe: barra lateral → **"Database"** → **"Extensions"** → buscar `postgis` y `pg_trgm` (aparecen como habilitadas).

**Paso A4 — Vista materializada de ventas (0:15)**
- Ruta: **"SQL Editor"** → **"+ New query"** → `SELECT * FROM mv_sales_by_category_monthly LIMIT 20;` → **"Run"**.
- Narrar: *"Los dashboards leen agregados precalculados en una vista materializada, en vez de recalcular en cada peticion."*

### Parte B — MongoDB Atlas (1:45)

**Paso B1 — Abrir las colecciones (0:30)**
- Ruta: cambiar a la pestana de **Atlas** (`cloud.mongodb.com`).
- Seleccionar arriba la **Organizacion** y el **Proyecto** correctos si pide.
- En la barra lateral izquierda, bajo **"Deployments"**, clic en **"Database"**.
- En la tarjeta del cluster, clic en el boton **"Browse Collections"**.
- En el panel izquierdo, expandir la base de datos **`ecommify`**: se ven las **5 colecciones** (`product_catalog`, `customer_profiles`, `seller_performance`, `geo_analytics`, `review_documents`). Clic en `product_catalog`.
- Narrar: *"Cada documento ya viene listo para lectura, sin joins: producto con su categoria, metricas y resenas en un solo documento."* Mostrar tambien `geo_analytics`.

**Paso B2 — Filtrar un documento (0:30)**
- Ruta: con `product_catalog` abierta, en la barra **"Filter"** escribir, por ejemplo, `{ "category.translated_name": "bed_bath_table" }` → boton **"Apply"** (o "Find").
- Narrar: *"La consulta por categoria devuelve el documento directamente."*

**Paso B3 — Mostrar el indice (0:30)**
- Ruta: en la misma coleccion, clic en la pestana **"Indexes"** (arriba, junto a "Find"/"Aggregation"/"Schema").
- Senalar el indice **`category.translated_name_1`** (y en `geo_analytics`, el indice compuesto **`state_1_city_1`**).
- Narrar: *"Este indice compuesto reduce los documentos examinados de mas de 20 mil a 20."*
- (Opcional, explain real) clic en la pestana **"Aggregation"** → construir `$match` → menu **"..."** (Export/Explain) → **"Explain"**; o conectarse por shell: boton **"Connect"** → **"Shell"** y correr `db.geo_analytics.find({state:"SP"}).explain("executionStats")`.

**Paso B4 — Job de sincronizacion (0:15)**
- Ruta: abrir en el editor/IDE el archivo **`tools/sync_postgres_to_mongo.py`** (o mostrarlo en GitHub).
- Narrar: *"La sincronizacion es un job batch idempotente: lee PostgreSQL y escribe en Atlas con upsert, asi se puede reejecutar sin duplicar."*

> Consejo: si una consulta cloud tarda por el free tier, tener listas las **capturas de respaldo** (o repetir desde el benchmark local) y comentarlo como l