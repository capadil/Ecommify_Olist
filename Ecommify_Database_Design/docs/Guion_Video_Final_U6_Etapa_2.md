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

**En pantalla:** alternar entre terminal/cliente SQL sobre Supabase y la consola de MongoDB Atlas. Tener las consultas preparadas y probadas antes de grabar.

Guion de acciones (narrar mientras se ejecuta):

1. **Supabase — modelo cargado (0:30).** Mostrar el panel con las 9 tablas y los conteos: 99.441 clientes y ordenes, 112.650 items, 103.886 pagos. "Estos son datos reales de Olist ya normalizados en Supabase."

2. **Consulta OLTP por order_id (0:45).** Ejecutar `EXPLAIN ANALYZE` de la busqueda por orden. "Con el indice sobre order_id y las FK internas, la busqueda puntual resuelve en fracciones de milisegundo y hace join con pagos e items por llave."

3. **Busqueda espacial PostGIS (0:45).** Ejecutar la consulta por radio geografico. "PostGIS con indice GiST permite encontrar ubicaciones dentro de un radio; es el tipo de consulta que solo el motor relacional resuelve bien."

4. **Vista materializada de ventas (0:30).** Consultar la MV de ventas por categoria/mes. "Los dashboards leen agregados precalculados en vez de recalcular en cada peticion."

5. **MongoDB Atlas — colecciones derivadas (0:45).** Mostrar las 5 colecciones y un documento de `product_catalog` y uno de `geo_analytics`. "Cada documento ya viene listo para lectura, sin joins."

6. **Consulta con indice en Atlas (0:30).** Ejecutar la consulta de `geo_analytics` por estado/ciudad con `explain`. "El indice compuesto reduce los documentos examinados de mas de 20 mil a 20."

7. **Job de sincronizacion (0:15).** Mostrar `tools/sync_postgres_to_mongo.py` y mencionar que es batch e idempotente con upsert.

> Consejo: si alguna consulta cloud tarda por el free tier, tener listas las capturas de respaldo y comentarlo como limitacion conocida.

---

## Bloque 5 — Resultados y analisis comparativo (9:00 - 11:30)

**En pantalla:** Slides 7 y 8 (graficas de rendimiento), luego Slide 9 (comparativa) y Slide 6 (CAP).

> "Estos son los resultados medidos con benchmarks antes y despues de las optimizaciones. En PostgreSQL, la busqueda OLTP por order_id paso de 25,9 milisegundos a 0,043: una reduccion del 99,83 por ciento. La busqueda espacial bajo un 98,66 por ciento. En MongoDB, la analitica geografica paso de examinar 20.888 documentos a solo 20 gracias al indice compuesto."

**Slide 9 (comparativa):**

> "Al comparar aspecto por aspecto, PostgreSQL gana en consultas transaccionales, integridad financiera y busqueda espacial. MongoDB gana en catalogo de lectura y flexibilidad de documentos. En dashboards hay empate controlado. La conclusion es que no hay un ganador absoluto: cada motor gana donde corresponde a su diseno."

**Slide 6 (CAP):**

> "Bajo el Teorema CAP, los modulos de ordenes, pagos y entidades maestras priorizan consistencia, es decir CP. El catalogo y los dashboards priorizan disponibilidad, AP, aceptando consistencia eventual porque sus datos son derivados y reconstruibles."

---

## Bloque 6 — Lecciones aprendidas y recomendaciones (11:30 - 13:00)

**En pantalla:** Slide 11 (lecciones) y Slide 12 (recomendaciones); opcional Slide 10 (escenarios).

> "Aprendimos que una arquitectura hibrida solo funciona con una fuente de verdad clara y con documentos derivados reconstruibles. Tambien que los supuestos de unicidad se deben validar con datos reales, como nos paso con las resenas."

> "Para escalar a diez veces el volumen recomendamos: migrar de free tier a planes productivos con backups y replicas, evolucionar la sincronizacion batch a incremental o CDC, e incorporar cache con Redis, busqueda con OpenSearch o Atlas Search, y observabilidad con Prometheus y Grafana. Y formalizar un CI/CD para los cambios de esquema, probando en Docker antes de aplicar en cloud."

Mencionar brevemente los escenarios de Black Friday (prioriza disponibilidad en lectura) y auditoria financiera (prioriza consistencia estricta).

---

## Bloque 7 — Conclusiones y cierre (13:00 - 14:00)

**En pantalla:** Slide 13 (conclusiones) y Slide 14 (cierre).

> "En conclusion, cumplimos los objetivos: disenamos, implementamos y evaluamos una arquitectura hibrida eficiente. PostgreSQL queda validado como nucleo transaccional y espacial; MongoDB Atlas como capa documental derivada. Las mejoras de rendimiento estan respaldadas con evidencia cuantitativa, y cada decision tecnologica esta justificada por modulo."

> "El siguiente paso natural es ejecutar pruebas formales de carga concurrente y mover la sincronizacion a un esquema incremental con observabilidad. Gracias por su atencion; el codigo y la documentacion completa estan en nuestro repositorio."

---

## Checklist de produccion

- [ ] Probar todas las consultas de la demo antes de grabar.
- [ ] Tener capturas de respaldo por si el free tier responde lento.
- [ ] Verificar audio claro y comparticion de pantalla legible (zoom de fuente en terminal y consultas).
- [ ] Confirmar duracion total entre 12 y 15 minutos.
- [ ] Mostrar el repositorio al inicio y al final.
- [ ] Exportar en 1080p y revisar que las graficas se lean bien.
