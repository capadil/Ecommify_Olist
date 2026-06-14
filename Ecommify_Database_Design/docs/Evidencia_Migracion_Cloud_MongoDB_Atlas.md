# Evidencia de migracion cloud a MongoDB Atlas

Este documento consolida la evidencia de implementacion de MongoDB Atlas como capa documental cloud de Ecommify. Docker se uso como ambiente reproducible para generar y validar las colecciones derivadas desde PostgreSQL antes de restaurarlas en Atlas; Atlas se valida como destino cloud documental para lectura y analitica.

## 1. Alcance de la migracion

| Elemento | Decision |
|---|---|
| Origen | MongoDB local en Docker |
| Destino | MongoDB Atlas Free Cluster |
| Cluster | ecommify-atlas |
| Base documental | `ecommify_analytics` |
| Modelo migrado | Colecciones documentales derivadas |
| Excluido del resultado final | `benchmark_results` |
| Fuente transaccional | PostgreSQL/PostGIS, validado localmente y en Supabase |

**Comentario importante:** MongoDB Atlas no reemplaza PostgreSQL ni Supabase. Su rol dentro de la arquitectura cloud es alojar la capa documental derivada: catalogo, perfiles, desempeno, analitica geografica y resenas enriquecidas.

## 2. Conexion inicial a Atlas

Se uso `mongosh` desde el contenedor local de MongoDB para validar conectividad hacia Atlas, reutilizando variables de PowerShell para no escribir credenciales directamente en el documento.

```powershell
docker compose exec mongo mongosh $ATLAS_URI --apiVersion 1 --username $ATLAS_USER --password $ATLAS_USER_PASS --eval "db.runCommand({ ping: 1 })"
```

Resultado:

```javascript
{ ok: 1 }
```

Bases visibles inicialmente:

| Base | Tamano observado |
|---|---:|
| sample_mflix | 175.06 MiB |
| admin | 0 B |
| local | 0 B |

**Comentario importante:** `sample_mflix` pertenece a los datos de ejemplo de Atlas y consume espacio del Free Tier. No forma parte de Ecommify; se recomienda eliminarla si no se usa.

## 3. Prueba controlada de escritura

Se creo temporalmente una coleccion de control para confirmar que el usuario tenia permisos de escritura en `ecommify_analytics`.

```javascript
const dbx = db.getSiblingDB('ecommify_analytics');
dbx.migration_control.insertOne({
  step: 'atlas_connection_test',
  created_at: new Date()
});
```

Resultado observado:

| Campo | Valor |
|---|---|
| step | atlas_connection_test |
| created_at | 2026-06-14T03:39:26.631Z |

Luego se elimino la coleccion temporal:

```javascript
db.getSiblingDB('ecommify_analytics').migration_control.drop();
```

Resultado:

```javascript
true
```

## 4. Creacion de colecciones, validadores e indices

Se ejecuto el script existente del proyecto contra Atlas:

```powershell
docker compose exec mongo mongosh $ATLAS_URI --apiVersion 1 --username $ATLAS_USER --password $ATLAS_USER_PASS /workspace/mongodb/schema/paso_09_crear_colecciones_validadores.js
```

Colecciones creadas:

| Coleccion |
|---|
| product_catalog |
| customer_profiles |
| seller_performance |
| geo_analytics |
| review_documents |

Indices validados en Atlas:

| Coleccion | Indices relevantes |
|---|---|
| `product_catalog` | `_id_`, `product_id_1` unique, `category.translated_name_1` |
| `customer_profiles` | `_id_`, `customer_id_1` unique, `segment_1`, `location.state_1` |
| `seller_performance` | `_id_`, `seller_id_1` unique, `location.state_1` |
| `geo_analytics` | `_id_`, `geo_key_1` unique, `state_1_city_1` |
| `review_documents` | `_id_`, `review_id_1_order_id_1` unique, `review_id_1`, `order_id_1`, `review_score_1` |

**Comentario importante:** crear primero validadores e indices garantiza que Atlas conserve el mismo contrato documental que MongoDB local antes de recibir datos.

## 5. Verificacion previa a la carga

Antes de restaurar documentos se confirmo que las colecciones de negocio estaban vacias:

| Coleccion | Documentos antes de migrar |
|---|---:|
| product_catalog | 0 |
| customer_profiles | 0 |
| seller_performance | 0 |
| geo_analytics | 0 |
| review_documents | 0 |

## 6. Dump desde MongoDB local

Se validaron herramientas disponibles en el contenedor:

| Herramienta | Version |
|---|---|
| mongodump | 100.17.0 |
| mongorestore | 100.17.0 |

El dump se genero desde MongoDB local:

```powershell
docker compose exec mongo mongodump --host localhost --port 27017 -u ecommify_admin -p ecommify_password --authenticationDatabase admin --db ecommify_analytics --archive=/tmp/ecommify_analytics.archive --gzip
```

Colecciones incluidas en el dump:

| Coleccion | Documentos exportados |
|---|---:|
| geo_analytics | 21.698 |
| product_catalog | 32.951 |
| seller_performance | 3.095 |
| benchmark_results | 8 |
| review_documents | 99.224 |
| customer_profiles | 99.441 |

Archivo generado:

| Archivo | Tamano |
|---|---:|
| `/tmp/ecommify_analytics.archive` | 21 MB |

**Comentario importante:** el dump incluyo `benchmark_results` porque existia en MongoDB local. Esa coleccion se restauro temporalmente y luego se elimino de Atlas para dejar solo el modelo documental funcional.

## 7. Restauracion en MongoDB Atlas

Se ejecuto `mongorestore` desde el contenedor hacia Atlas:

```powershell
docker compose exec mongo mongorestore --uri $ATLAS_URI --username $ATLAS_USER --password $ATLAS_USER_PASS --authenticationDatabase admin --nsInclude "ecommify_analytics.*" --archive=/tmp/ecommify_analytics.archive --gzip
```

Resultado global:

| Metrica | Resultado |
|---|---:|
| Documentos restaurados | 256.417 |
| Documentos fallidos | 0 |

Durante la restauracion aparecio una advertencia de version:

```text
This archive came from MongoDB 7.0.37, but you are restoring to 8.0.26.
Cross-version dump & restore is unsupported.
```

**Comentario importante:** aunque la restauracion finalizo sin fallos y los conteos coinciden, la advertencia debe documentarse. Para una migracion productiva se recomienda alinear versiones o usar herramientas compatibles oficialmente con la version destino.

## 8. Limpieza posterior a la restauracion

Se elimino `benchmark_results` de Atlas porque corresponde a evidencia local, no a una coleccion funcional del modelo documental cloud.

```javascript
db.getSiblingDB('ecommify_analytics').benchmark_results.drop();
```

Resultado:

```javascript
true
```

## 9. Validacion final de datos en Atlas

Conteos finales en MongoDB Atlas:

| Coleccion | Documentos |
|---|---:|
| product_catalog | 32.951 |
| customer_profiles | 99.441 |
| seller_performance | 3.095 |
| geo_analytics | 21.698 |
| review_documents | 99.224 |

Estos conteos coinciden con MongoDB local despues de la sincronizacion PostgreSQL -> MongoDB.

## 10. Conclusiones de la migracion

La implementacion de MongoDB Atlas queda validada como primera version cloud documental. La carga partio de Docker porque ese entorno ya habia materializado y verificado las proyecciones documentales desde PostgreSQL.

| Criterio | Resultado |
|---|---|
| Conexion Atlas desde Docker | Cumplido |
| Escritura controlada en Atlas | Cumplido |
| Colecciones creadas | Cumplido |
| Indices preservados/validados | Cumplido |
| Dump local generado | Cumplido |
| Restore en Atlas | 256.417 documentos, 0 fallos |
| `benchmark_results` eliminado de Atlas | Cumplido |
| Conteos finales de negocio | Coinciden con MongoDB local |

## 11. Evidencia de rendimiento en Atlas con `.explain("executionStats")`

Despues de validar la carga en Atlas se ejecutaron consultas con `explain("executionStats")` sobre las colecciones documentales principales. El objetivo fue comprobar que Atlas usa los indices esperados y que las consultas examinan un volumen controlado de documentos.

**Comentario importante:** en estas pruebas `executionTimeMillis` aparece como `0 ms` en varios casos. Esto no significa que la consulta no tenga costo, sino que el tiempo medido queda por debajo de la resolucion reportada por MongoDB para este volumen y estado de cache. Por eso la evidencia mas relevante es la relacion entre `nReturned`, `totalDocsExamined` y `totalKeysExamined`.

| Coleccion | Patron evaluado | Indice usado | Documentos retornados | Documentos examinados | Llaves examinadas | Tiempo |
|---|---|---|---:|---:|---:|---:|
| `product_catalog` | Categoria `health_beauty` | `category.translated_name_1` | 20 | 20 | 20 | 0 ms |
| `customer_profiles` | Estado `SP` | `location.state_1` | 20 | 20 | 20 | 0 ms |
| `geo_analytics` | Estado `SP` y ciudad `sao paulo` | `state_1_city_1` | 20 | 20 | 20 | 0 ms |
| `review_documents` | `review_score <= 2` | `review_score_1` | 0 | 0 | 0 | 0 ms |

Interpretacion:

- Las tres primeras consultas muestran una relacion eficiente: por cada documento retornado se examina un documento y una llave del indice.
- `geo_analytics` confirma el uso adecuado del indice compuesto `{ state: 1, city: 1 }`, que corresponde al patron geografico principal.
- La consulta de `review_documents` no retorno documentos con el filtro evaluado en Atlas. La prueba valida que el indice existe y se puede forzar con `hint`, pero no sirve como comparacion de eficiencia porque no hubo resultados. Para una evidencia mas fuerte se recomienda repetirla con un valor de `review_score` que retorne documentos en Atlas.

## 12. Conclusiones de la migracion

La arquitectura cloud queda implementada en primera version:

```text
Supabase PostgreSQL/PostGIS -> capa relacional y espacial: validado
MongoDB Atlas               -> capa documental derivada: validado
```
