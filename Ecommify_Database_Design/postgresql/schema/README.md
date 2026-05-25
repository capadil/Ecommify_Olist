# PostgreSQL schema

Los archivos se organizan en orden ascendente por paso tecnico.

| Orden | Archivo | Ejecutar | Descripcion |
|---|---|---|---|
| 1 | `paso_01_crear_esquema.sql` | Si | Crea el esquema `ecommify`. |
| 2 | `paso_02_crear_tablas_base.sql` | Si | Crea tablas base con PK tecnicas, IDs Olist `TEXT UNIQUE`, FK internas, `CHECK`, `JSONB`, arrays y auditoria. |
| 3 | `paso_03_crear_indices.sql` | Si | Crea indices para IDs Olist, FK internas, fechas, `JSONB` y arrays. |
| 4 | `paso_04_crear_triggers_updated_at.sql` | Si | Crea la funcion y triggers para mantener `updated_at`. |
| 5 | `paso_05_crear_vistas_materializadas.sql` | Si | Crea vistas materializadas `WITH NO DATA`. |
| 6 | `paso_06_borrador_particionamiento_orders.sql` | Discusion tecnica | Documenta la alternativa de particionamiento de `orders` y sus implicaciones sobre PK/FK. |

Despues del paso 05, la carga de datos precede al refresh de vistas materializadas definido en `../queries`.
