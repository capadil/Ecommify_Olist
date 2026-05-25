# PostgreSQL schema

Ejecutar estos archivos en orden ascendente por paso.

| Orden | Archivo | Ejecutar | Descripcion |
|---|---|---|---|
| 1 | `paso_01_crear_esquema.sql` | Si | Crea el esquema `ecommify`. |
| 2 | `paso_02_crear_tablas_base.sql` | Si | Crea tablas base, PK, FK, `CHECK`, `JSONB`, arrays y auditoria. |
| 3 | `paso_03_crear_indices.sql` | Si | Crea indices para claves, fechas, `JSONB` y arrays. |
| 4 | `paso_04_crear_triggers_updated_at.sql` | Si | Crea la funcion y triggers para mantener `updated_at`. |
| 5 | `paso_05_crear_vistas_materializadas.sql` | Si | Crea vistas materializadas `WITH NO DATA`. |
| 6 | `paso_06_borrador_particionamiento_orders.sql` | No automatico | Documenta la alternativa de particionamiento de `orders`; requiere decision del equipo antes de implementarse. |

Despues del paso 05 se deben cargar datos y luego ejecutar el paso 07 en `../queries`.
