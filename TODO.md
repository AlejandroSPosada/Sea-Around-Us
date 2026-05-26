# TODO — Sistemas Intensivos en Datos: The Sea Around Us

**Sistemas Intensivos en Datos — 2026-1 — Universidad EAFIT**

> Las tareas son secuenciales por bloque: Samuel depende de que Alejandro termine la ingestión antes de ejecutar los Jobs de Glue; Gabriela depende de que el catálogo esté listo antes de ejecutar las consultas en Athena.

---

# PARTE 1: CHECKLISTS

---

## ALEJANDRO SEPÚLVEDA — Infraestructura S3 e Ingestión de Datos

**1.1 Configurar el bucket S3**
- [ ] Crear el bucket principal en AWS S3 (ej: `seaaroundus-data-<iniciales>`)
- [ ] Crear la estructura de prefijos: `raw/global/`, `raw/highseas/`, `raw/eez/`, `processed/`, `query-results/`
- [ ] Habilitar versionado en el bucket
- [ ] Crear el IAM Role con permisos de lectura/escritura sobre S3 para los servicios Glue y Athena
- [ ] Anotar el nombre del bucket y el ARN del role en `docs/architecture.md`

**1.2 Descargar y validar los archivos CSV**
- [ ] Descargar `SAU-GLOBAL-1-v48-0.csv` desde seaaroundus.org
- [ ] Descargar `SAU-HighSeas-71-v48-0.csv` desde seaaroundus.org
- [ ] Descargar `SAU-EEZ-242-v48-0.csv` desde seaaroundus.org
- [ ] Verificar encoding UTF-8 en los tres archivos
- [ ] Verificar conteo de filas en cada archivo y registrarlo en `docs/architecture.md`
- [ ] Confirmar que los encabezados coinciden con los esquemas documentados en el README

**1.3 Subir los CSV a S3**
- [ ] Subir `SAU-GLOBAL-1-v48-0.csv` a `s3://<bucket>/raw/global/`
- [ ] Subir `SAU-HighSeas-71-v48-0.csv` a `s3://<bucket>/raw/highseas/`
- [ ] Subir `SAU-EEZ-242-v48-0.csv` a `s3://<bucket>/raw/eez/`
- [ ] Verificar en la consola de S3 que los tres archivos están accesibles
- [ ] Compartir el nombre del bucket y las rutas con Samuel Aristizabal

**1.4 Documentar la arquitectura y escalabilidad**
- [ ] Redactar el diagrama del pipeline (S3 → Glue → Athena) en `docs/architecture.md`
- [ ] Documentar las decisiones de estructura de prefijos en S3
- [ ] Proponer y documentar la estrategia de particionado para el dataset completo (todas las regiones oceánicas)
- [ ] Estimar costo aproximado en AWS si se procesara el dataset global completo
- [ ] Registrar los criterios de diseño que garantizan escalabilidad (Parquet, particionado, serverless)

---

## SAMUEL ARISTIZABAL — ETL, Limpieza y Catálogo de Datos (Glue)

> Prerequisito: Alejandro debe haber terminado la sección 1.3 y compartido el nombre del bucket y las rutas.

**2.1 Crear el Job de Glue para SAU-GLOBAL-1 (alta mar global)**
- [ ] Crear el Job en AWS Glue apuntando a `s3://<bucket>/raw/global/`
- [ ] Normalizar nombres de columnas a snake_case
- [ ] Castear `year` a entero, `tonnes` y `landed_value` a float
- [ ] Manejar valores nulos: registrar cuántos hay por columna y decidir tratamiento
- [ ] Guardar el resultado en `s3://<bucket>/processed/global/` en formato Parquet, particionado por `year`
- [ ] Verificar conteo de filas: processed debe tener el mismo número que raw (descontando nulos eliminados)

**2.2 Crear el Job de Glue para SAU-HighSeas-71 (Pacífico Central Occidental)**
- [ ] Crear el Job apuntando a `s3://<bucket>/raw/highseas/`
- [ ] Aplicar los mismos pasos de normalización, casteo y manejo de nulos
- [ ] Guardar en `s3://<bucket>/processed/highseas/` en formato Parquet, particionado por `year`
- [ ] Verificar conteo de filas

**2.3 Crear el Job de Glue para SAU-EEZ-242 (ZEE de Fiyi)**
- [ ] Crear el Job apuntando a `s3://<bucket>/raw/eez/`
- [ ] Aplicar normalización, casteo y manejo de nulos
- [ ] Tratar columnas adicionales: `data_layer`, `uncertainty_score`, `country`
- [ ] Guardar en `s3://<bucket>/processed/eez/` en formato Parquet, particionado por `year`
- [ ] Verificar conteo de filas

**2.4 Configurar el Glue Data Catalog**
- [ ] Crear la base de datos en el catálogo: `seaaroundus_db`
- [ ] Configurar un Crawler para `processed/global/` y ejecutarlo
- [ ] Configurar un Crawler para `processed/highseas/` y ejecutarlo
- [ ] Configurar un Crawler para `processed/eez/` y ejecutarlo
- [ ] Verificar que los tres Crawlers inferieron correctamente los esquemas (tipos de datos, particiones)
- [ ] Corregir en el catálogo cualquier tipo de dato mal inferido
- [ ] Documentar el esquema final de cada tabla en `infra/glue/`

**2.5 Notificar a Gabriela Lucía Martínez**
- [ ] Confirmar que las tres tablas están en el catálogo y son consultables
- [ ] Compartir el nombre de la base de datos del catálogo (`seaaroundus_db`) y los nombres de tabla
- [ ] Compartir el prefijo del bucket de resultados de Athena (`s3://<bucket>/query-results/`)

---

## GABRIELA LUCÍA MARTÍNEZ — Consultas Athena y Visualización

> Prerequisito: Samuel debe haber terminado la sección 2.5 y compartido la información del catálogo.

**3.1 Configurar Amazon Athena**
- [ ] Abrir Athena en la consola de AWS
- [ ] Configurar el bucket de resultados: `s3://<bucket>/query-results/`
- [ ] Seleccionar la base de datos `seaaroundus_db`
- [ ] Verificar conectividad con una consulta simple (`SELECT COUNT(*) FROM global`) en cada tabla
- [ ] Confirmar que las tres tablas devuelven resultados correctos

**3.2 Consultas exploratorias** (`queries/exploratory/`)
- [ ] Top 10 entidades pesqueras con mayor captura total (toneladas) en el dataset global
- [ ] Tendencia histórica de toneladas capturadas en la ZEE de Fiyi por año (1950–2018)
- [ ] Comparación de capturas en alta mar vs. ZEE para el área del Pacífico Central Occidental
- [ ] Distribución de capturas por `fishing_sector` (industrial vs. subsistencia) en la ZEE de Fiyi
- [ ] Porcentaje de capturas reportadas vs. no reportadas (`reporting_status`) por fuente de datos
- [ ] Top 5 especies (`scientific_name`) más capturadas por década en la ZEE de Fiyi
- [ ] Evolución del valor económico total (`landed_value`) por año en el dataset global
- [ ] Guardar los resultados de cada consulta desde Athena (exportar a CSV)

**3.3 Consultas para el informe final** (`queries/reports/`)
- [ ] Consolidar las 3 consultas más relevantes con comentarios explicativos
- [ ] Validar que los resultados son consistentes entre las tres fuentes de datos
- [ ] Cruzar datos de `SAU-HighSeas-71` y `SAU-EEZ-242` para comparar la región del Pacífico

**3.4 Visualizaciones y reporte analítico**
- [ ] Definir qué gráficas se incluirán: series de tiempo, barras comparativas, top N
- [ ] Generar las visualizaciones con la herramienta elegida (QuickSight, Python/matplotlib o Jupyter Notebook)
- [ ] Incluir al menos: (1) tendencia histórica de capturas en Fiyi, (2) top países por captura global, (3) comparación alta mar vs. ZEE
- [ ] Documentar el diseño y las decisiones de visualización en `viz/dashboard_notes.md`
- [ ] Exportar las gráficas finales en formato imagen o HTML para incluir en el informe

---

## Tareas Compartidas

- [ ] Acordar convenciones de nombres (bucket, tablas, columnas) antes de comenzar
- [ ] Revisar y aprobar el README.md antes de la entrega
- [ ] Ejecutar una prueba de integración end-to-end: S3 raw → Glue → Athena → resultado en pantalla
- [ ] Preparar el informe técnico final con: arquitectura, decisiones de diseño, consultas destacadas, visualizaciones y análisis de escalabilidad
- [ ] Preparar la presentación o sustentación del proyecto

---

*Universidad EAFIT — Ingeniería de Sistemas — 2026-1*
