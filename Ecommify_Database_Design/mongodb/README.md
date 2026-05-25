# MongoDB - Diseno documental derivado

MongoDB se usa como capa derivada de lectura y analitica. No reemplaza a PostgreSQL como fuente de verdad.

## Relacion con las llaves PostgreSQL

PostgreSQL usa llaves tecnicas internas `*_sk` para PK/FK y conserva los IDs Olist como `TEXT UNIQUE`. MongoDB debe exponer los IDs Olist (`product_id`, `customer_id`, `seller_id`, `order_id`, `review_id`) porque son utiles para trazabilidad y lectura, pero no son la fuente de integridad relacional.

## Secuencia tecnica

1. Ejecutar primero los pasos 01 a 08 de PostgreSQL.
2. Preparar o sincronizar documentos derivados desde PostgreSQL.
3. Ejecutar `schema/paso_09_crear_colecciones_validadores.js`.
4. Cargar o actualizar documentos derivados segun `seed_data/README.md`.
5. Usar `queries/paso_10_consultas_analiticas_ejemplo.js` como consultas de control tecnico sobre documentos derivados.

## Scripts principales

| Paso | Archivo | Proposito |
|---|---|---|
| 09 | `schema/paso_09_crear_colecciones_validadores.js` | Crear colecciones, validadores e indices de MongoDB. |
| 10 | `queries/paso_10_consultas_analiticas_ejemplo.js` | Consultas de ejemplo sobre documentos derivados. |

## Decisiones aplicadas

- Usar tipos documentales de MongoDB: `object`, `array`, `string`, `number`, `date`, `boolean`.
- No usar `JSONB` en MongoDB.
- Colecciones derivadas: `product_catalog`, `customer_profiles`, `seller_performance`, `geo_analytics`, `review_documents`.
- Conservar IDs Olist en documentos para trazabilidad.
- No modelar `*_sk` como requisito de consulta documental, salvo que se necesite auditoria interna de sincronizacion.
