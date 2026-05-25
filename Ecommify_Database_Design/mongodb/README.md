# MongoDB - Borradores de ejecucion

MongoDB se usa como capa derivada de lectura y analitica. No reemplaza a PostgreSQL como fuente de verdad.

## Orden recomendado

1. Ejecutar primero los pasos 01 a 08 de PostgreSQL.
2. Preparar o sincronizar documentos derivados desde PostgreSQL.
3. Ejecutar `schema/paso_09_crear_colecciones_validadores.js`.
4. Cargar o actualizar documentos derivados segun `seed_data/README.md`.
5. Ejecutar `queries/paso_10_consultas_analiticas_ejemplo.js` para validacion.

## Scripts principales

| Paso | Archivo | Proposito |
|---|---|---|
| 09 | `schema/paso_09_crear_colecciones_validadores.js` | Crear colecciones, validadores e indices de MongoDB. |
| 10 | `queries/paso_10_consultas_analiticas_ejemplo.js` | Consultas de ejemplo sobre documentos derivados. |

## Decisiones aplicadas

- Usar tipos documentales de MongoDB: `object`, `array`, `string`, `number`, `date`, `boolean`.
- No usar `JSONB` en MongoDB.
- Colecciones derivadas: `product_catalog`, `customer_profiles`, `seller_performance`, `geo_analytics`, `review_documents`.
