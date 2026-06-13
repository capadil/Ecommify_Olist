# Evidencias MongoDB - Actividad 2

Este documento consolida las evidencias de ejecucion y validacion del componente MongoDB dentro del ambiente Docker local de Ecommify. MongoDB se utiliza como capa documental derivada para lectura y analitica, sin reemplazar a PostgreSQL como fuente de verdad.

La salida completa de consola se conserva en `mongodb/evidencias` como evidencia cruda. Este archivo presenta una lectura academica de los resultados obtenidos.

## 1. Objetivo de la validacion

Las pruebas ejecutadas buscan demostrar que la capa documental cumple su proposito dentro de la arquitectura hibrida:

- Crear colecciones documentales con validadores e indices.
- Poblar documentos derivados desde PostgreSQL.
- Mantener trazabilidad con IDs Olist.
- Evitar duplicacion mediante `upsert`.
- Resolver la unicidad de `review_documents` con indice compuesto.
- Ejecutar consultas analiticas sobre documentos ya materializados.

## 2. Validacion de indices por coleccion

Se validaron los indices de las colecciones principales:

```javascript
db.product_catalog.getIndexes()
db.customer_profiles.getIndexes()
db.seller_performance.getIndexes()
db.geo_analytics.getIndexes()
db.review_documents.getIndexes()
```

Resultados relevantes:

```text
product_catalog:
- product_id_1 unique
- category.translated_name_1

customer_profiles:
- customer_id_1 unique
- segment_1
- location.state_1

seller_performance:
- seller_id_1 unique
- location.state_1

geo_analytics:
- geo_key_1 unique
- state_1_city_1

review_documents:
- review_id_1_order_id_1 unique
- review_id_1
- order_id_1
- review_score_1
```

Interpretacion:

Los indices evidencian que MongoDB fue configurado como capa de lectura y analitica. Las llaves unicas conservan trazabilidad documental, mientras los indices secundarios responden a patrones de consulta: categoria, estado, ciudad, puntaje de resena y busquedas por identificadores.

El caso de `review_documents` es especialmente importante: inicialmente se habia usado `review_id` como unico, pero la evidencia mostro que solo se cargaban 994 documentos. Al ajustar la unicidad a `{ review_id: 1, order_id: 1 }`, el conteo subio a 99.224 documentos. Esto demuestra una correccion de modelado basada en datos reales.

## 3. Validacion de conteos documentales

Conteos finales:

```javascript
db.product_catalog.countDocuments()
db.customer_profiles.countDocuments()
db.seller_performance.countDocuments()
db.geo_analytics.countDocuments()
db.review_documents.countDocuments()
```

Resultado:

```text
product_catalog:     32951
customer_profiles:   99441
seller_performance:  3095
geo_analytics:       21698
review_documents:    99224
```

Interpretacion:

Los conteos confirman que la sincronizacion PostgreSQL -> MongoDB fue ejecutada correctamente. Cada coleccion representa una vista documental derivada:

- `product_catalog`: catalogo enriquecido por producto.
- `customer_profiles`: perfil analitico por cliente.
- `seller_performance`: metricas agregadas por vendedor.
- `geo_analytics`: agregados geograficos por ciudad, estado y mes.
- `review_documents`: resenas enriquecidas con contexto de orden, cliente y producto.

Estos conteos son coherentes con las tablas y vistas materializadas de PostgreSQL usadas como fuente.

## 4. Validacion de base de datos destino

Comando ejecutado:

```powershell
docker compose exec mongo mongosh -u ecommify_admin -p ecommify_password --authenticationDatabase admin --eval "db.getSiblingDB('ecommify_analytics').review_documents.countDocuments()"
```

Resultado:

```text
99224
```

Interpretacion:

Esta prueba valida que las consultas apuntan a la base `ecommify_analytics`, no a la base por defecto `test`. Esto es relevante porque MongoDB permite cambiar de base dentro de la sesion, y una validacion contra la base incorrecta podria dar conteos en cero.

## 5. Validacion de consultas analiticas

Comando ejecutado:

```powershell
docker compose exec mongo mongosh -u ecommify_admin -p ecommify_password --authenticationDatabase admin /workspace/mongodb/queries/paso_10_consultas_analiticas_ejemplo.js
```

El script ejecuta consultas sobre las colecciones derivadas e imprime secciones separadas:

```text
=== Catalogo de productos por categoria traducida ===
=== Clientes principales por valor total pagado ===
=== Desempeno de vendedores por estado SP ===
=== Dashboard de analitica geografica SP ===
=== Documentos de resenas con calificacion baja ===
```

Interpretacion:

La ejecucion confirma que MongoDB no solo contiene documentos, sino que permite resolver consultas analiticas de lectura sin consultar directamente las tablas transaccionales de PostgreSQL. Esto esta alineado con la arquitectura hibrida definida: PostgreSQL conserva integridad y transacciones, mientras MongoDB sirve estructuras documentales optimizadas para lectura.

## 6. Ejemplo de analitica geografica

Resultado representativo:

```text
geo_key: SP|sao paulo|2018-05-01
city: sao paulo
orders_count: 1222
total_payment_value: 183243.63
```

Interpretacion:

La coleccion `geo_analytics` permite consultar rapidamente ventas por ciudad, estado y mes. Este resultado es una evidencia de que los datos espaciales y de pedidos procesados en PostgreSQL pueden materializarse como documentos analiticos en MongoDB.

## 7. Ejemplo de resenas con baja calificacion

Resultado representativo:

```text
review_score: 1
product_context:
  category: computers_accessories
comment.message: O cartucho "original HP" 60XL nao e reconhecido pela impressora...
```

Interpretacion:

La coleccion `review_documents` agrupa resenas con contexto de orden, producto y cliente. Esto facilita consultas orientadas a experiencia del cliente y analisis de reclamos sin requerir joins en tiempo de lectura.

## 8. Conclusiones

Las evidencias permiten concluir que la implementacion MongoDB cumple el alcance definido:

- Las colecciones documentales fueron creadas con validadores e indices.
- La sincronizacion desde PostgreSQL cargo documentos derivados completos.
- El uso de `upsert` permite repetir la sincronizacion sin duplicar documentos.
- La correccion del indice compuesto en `review_documents` resolvio una inconsistencia detectada con datos reales.
- MongoDB funciona como capa analitica derivada, no como fuente transaccional principal.

