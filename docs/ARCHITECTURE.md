# ARCHITECTURE.md — Infraestructura de Datos: The Sea Around Us

**Sistemas Intensivos en Datos — 2026-1 — Universidad EAFIT**

---

## 1. Visión General

La solución implementa un pipeline de datos en la nube sobre AWS que cubre las etapas de ingestión, transformación, catalogación y análisis de los datos de capturas pesqueras del proyecto The Sea Around Us. El diseño sigue el patrón de arquitectura por capas (medallion architecture en su variante raw/processed), usando servicios serverless o administrados en su totalidad para minimizar la operación de infraestructura.

Bucket name: seaaroundus-data-eafit

Filas en SAU-EEZ-242-v48-0 1: 27049

Filas en SAU-GLOBAL-1-v48-0 1: 561675

Filas en SAU-HighSeas-71-v48-0 1: 26720

---

## 2. Diagrama de Arquitectura

```
+------------------+
|   Fuente de datos |
|  seaaroundus.org  |
|  (3 archivos CSV) |
+--------+---------+
         |
         | Descarga manual
         v
+---------------------------+
|        Amazon S3          |
|  Capa RAW                 |
|  raw/global/              |
|  raw/highseas/            |
|  raw/eez/                 |
+--------+------------------+
         |
         | AWS Glue Jobs (ETL)
         | - Normalización de columnas
         | - Casteo de tipos de datos
         | - Manejo de valores nulos
         v
+---------------------------+
|        Amazon S3          |
|  Capa PROCESSED           |
|  processed/global/        |   <-- Parquet, particionado por year
|  processed/highseas/      |   <-- Parquet, particionado por year
|  processed/eez/           |   <-- Parquet, particionado por year
+--------+------------------+
         |
         | AWS Glue Crawlers
         v
+---------------------------+
|   AWS Glue Data Catalog   |
|  Base de datos:           |
|  seaaroundus_db           |
|  - tabla: global          |
|  - tabla: highseas        |
|  - tabla: eez             |
+--------+------------------+
         |
         | Amazon Athena (SQL serverless)
         v
+---------------------------+
|       Amazon Athena       |
|  Consultas exploratorias  |
|  Consultas de reporte     |
|  Resultados → S3          |
|  query-results/           |
+--------+------------------+
         |
         | Exportación CSV / QuickSight / Jupyter
         v
+---------------------------+
|   Visualizaciones y       |
|   Reporte Analítico       |
+---------------------------+
```

---

## 3. Descripción de Capas

### 3.1 Capa de Ingesta — Amazon S3 (raw)

Los tres archivos CSV se cargan manualmente al bucket S3 bajo el prefijo `raw/`. Esta capa conserva los datos exactamente como vienen de la fuente, sin ninguna modificación, como respaldo de la información original.

| Prefijo S3 | Archivo fuente |
|---|---|
| `raw/global/` | `SAU-GLOBAL-1-v48-0.csv` |
| `raw/highseas/` | `SAU-HighSeas-71-v48-0.csv` |
| `raw/eez/` | `SAU-EEZ-242-v48-0.csv` |

**Decisiones de diseño:**
- Se usa un único bucket con prefijos en lugar de tres buckets separados para simplificar la gestión de permisos IAM y reducir costos de operación.
- El versionado está habilitado en el bucket para permitir recuperar versiones anteriores de los archivos si se actualizan en el futuro.

### 3.2 Capa de Transformación — AWS Glue Jobs

Cada archivo CSV tiene su propio Glue Job independiente. Esto permite ejecutarlos en paralelo, facilita el mantenimiento individual de cada transformación y hace más claro el linaje de datos.

**Transformaciones aplicadas en los tres Jobs:**
- Normalización de nombres de columnas a snake_case
- Casteo explícito de tipos: `year` → integer, `tonnes` → float, `landed_value` → float
- Identificación y tratamiento de valores nulos en columnas críticas (`tonnes`, `landed_value`, `fishing_entity`)
- Escritura del resultado en formato Parquet con compresión Snappy

**Salida de cada Job:**

| Job | Entrada | Salida | Partición |
|---|---|---|---|
| `clean_global` | `raw/global/` | `processed/global/` | `year` |
| `clean_highseas` | `raw/highseas/` | `processed/highseas/` | `year` |
| `clean_eez` | `raw/eez/` | `processed/eez/` | `year` |

**Justificación del formato Parquet:**
- Almacenamiento columnar: Athena solo lee las columnas que una consulta necesita, reduciendo el volumen de datos escaneados y por tanto el costo.
- Compresión eficiente: los archivos CSV originales se reducen significativamente en tamaño.
- Soporte nativo en Athena y Glue sin configuración adicional.

**Justificación del particionado por `year`:**
- La mayoría de las consultas analíticas filtran por rango de años. El particionado permite que Athena descarte particiones irrelevantes sin leerlas (partition pruning).
- El dataset cubre 1950–2018 (68 años), lo que genera 68 particiones por tabla: un número manejable que no genera overhead de metadatos.

### 3.3 Capa de Catalogación — AWS Glue Data Catalog

Los Crawlers de Glue inspeccionan los datos procesados en S3 y registran automáticamente el esquema de cada tabla en el catálogo. Athena usa este catálogo para resolver nombres de columnas y tipos antes de ejecutar cualquier consulta.

**Base de datos del catálogo:** `seaaroundus_db`

| Tabla en el catálogo | Origen en S3 |
|---|---|
| `global` | `processed/global/` |
| `highseas` | `processed/highseas/` |
| `eez` | `processed/eez/` |

**Esquema final — tabla `global`:**

| Columna | Tipo | Descripción |
|---|---|---|
| `year` | int | Año de la captura |
| `fishing_entity` | string | País o entidad pesquera |
| `fishing_sector` | string | Sector (Industrial, Artisanal, Subsistence, Recreational) |
| `catch_type` | string | Tipo de captura (Landings, Discards) |
| `reporting_status` | string | Reported o Unreported |
| `gear_type` | string | Tipo de arte de pesca |
| `end_use_type` | string | Uso final (Direct human consumption, Discards, etc.) |
| `tonnes` | double | Toneladas capturadas |
| `landed_value` | double | Valor en USD 2010 |

**Esquema final — tabla `highseas`:**

| Columna | Tipo | Descripción |
|---|---|---|
| `area_name` | string | Nombre del área de alta mar |
| `area_type` | string | Tipo de área (high_seas) |
| `year` | int | Año de la captura |
| `scientific_name` | string | Nombre científico de la especie |
| `common_name` | string | Nombre común de la especie |
| `functional_group` | string | Grupo funcional ecológico |
| `commercial_group` | string | Grupo comercial |
| `fishing_entity` | string | País o entidad pesquera |
| `fishing_sector` | string | Sector de pesca |
| `catch_type` | string | Tipo de captura |
| `reporting_status` | string | Reported o Unreported |
| `gear_type` | string | Tipo de arte de pesca |
| `end_use_type` | string | Uso final |
| `tonnes` | double | Toneladas capturadas |
| `landed_value` | double | Valor en USD 2010 |

**Esquema final — tabla `eez`:**

| Columna | Tipo | Descripción |
|---|---|---|
| `area_name` | string | Nombre del área (Fiji) |
| `area_type` | string | Tipo de área (eez) |
| `data_layer` | string | Tipo de dato (Reconstructed domestic catch, etc.) |
| `uncertainty_score` | int | Puntaje de incertidumbre de la reconstrucción |
| `year` | int | Año de la captura |
| `scientific_name` | string | Nombre científico de la especie |
| `fish_name` | string | Nombre común de la especie |
| `functional_group` | string | Grupo funcional ecológico |
| `commercial_group` | string | Grupo comercial |
| `country` | string | País que realizó la captura |
| `fishing_sector` | string | Sector de pesca |
| `catch_type` | string | Tipo de captura |
| `reporting_status` | string | Reported o Unreported |
| `gear_type` | string | Tipo de arte de pesca |
| `end_use_type` | string | Uso final |
| `tonnes` | double | Toneladas capturadas |
| `landed_value` | double | Valor en USD 2010 |

### 3.4 Capa de Análisis — Amazon Athena

Athena ejecuta consultas SQL estándar (compatible con Presto/Trino) directamente sobre los archivos Parquet en S3, sin necesidad de cargar los datos en ningún motor de base de datos. Los resultados se almacenan automáticamente en `s3://<bucket>/query-results/`.

**Configuración:**
- Workgroup: default (o uno propio del proyecto)
- Output location: `s3://<bucket>/query-results/`
- Base de datos activa: `seaaroundus_db`

### 3.5 Capa de Visualización

Los resultados de las consultas Athena se exportan en CSV y se procesan con la herramienta de visualización elegida. Las gráficas planificadas son:

- Serie de tiempo: toneladas capturadas por año en la ZEE de Fiyi (1950–2018)
- Barras: top 10 entidades pesqueras por captura total en el dataset global
- Barras comparativas: capturas en alta mar vs. ZEE en la región del Pacífico Central Occidental
- Distribución: desglose por `fishing_sector` e `end_use_type`

---

## 4. Estructura del Bucket S3

```
s3://<bucket>/
├── raw/
│   ├── global/
│   │   └── SAU-GLOBAL-1-v48-0.csv
│   ├── highseas/
│   │   └── SAU-HighSeas-71-v48-0.csv
│   └── eez/
│       └── SAU-EEZ-242-v48-0.csv
├── processed/
│   ├── global/
│   │   ├── year=1950/part-00000.parquet
│   │   ├── year=1951/part-00000.parquet
│   │   └── ...
│   ├── highseas/
│   │   ├── year=1950/part-00000.parquet
│   │   └── ...
│   └── eez/
│       ├── year=1950/part-00000.parquet
│       └── ...
└── query-results/
    └── <resultados generados automáticamente por Athena>
```

---

## 5. Seguridad y Permisos (IAM)

Se usa un único IAM Role con las siguientes políticas:

| Servicio | Permisos |
|---|---|
| S3 | `s3:GetObject`, `s3:PutObject`, `s3:ListBucket` sobre el bucket del proyecto |
| Glue | `glue:GetDatabase`, `glue:GetTable`, `glue:CreateTable`, `glue:UpdateTable` |
| Athena | `athena:StartQueryExecution`, `athena:GetQueryResults` |

Este role se asigna a los Glue Jobs y se referencia desde Athena. No se otorgan permisos sobre otros buckets ni servicios fuera del alcance del proyecto.

---

## 6. Escalabilidad

El diseño actual trabaja con tres archivos de una región específica (Fiyi y su entorno). El dataset completo de The Sea Around Us abarca todas las regiones oceánicas del mundo, lo que implica un volumen significativamente mayor de archivos y registros. Las siguientes decisiones de diseño garantizan que la solución pueda escalar a ese escenario sin cambios estructurales:

**Particionado multi-nivel para el dataset completo:**
Al incorporar todas las regiones, se recomienda agregar una partición por `area_name` o `region` antes de la partición por `year`, produciendo una estructura `region=X/year=Y/`. Esto permite que las consultas filtradas por región y año sean especialmente eficientes.

**Glue Jobs parametrizados:**
Los Jobs actuales pueden convertirse en Jobs parametrizados que reciben la ruta de entrada y salida como argumentos. Esto permite procesar cualquier nuevo archivo CSV con el mismo código, sin duplicar lógica.

**Crawlers incrementales:**
Glue soporta Crawlers incrementales que solo procesan las particiones nuevas desde la última ejecución. Al agregar datos de nuevas regiones o años, el Crawler no re-cataloga lo que ya existe.

**Costo estimado (referencial):**
Para el dataset completo (~200 archivos CSV, estimado ~10 GB en crudo):
- S3: menos de USD 0.25/mes en almacenamiento (con compresión Parquet, ~2 GB)
- Glue Jobs: costo único de transformación, del orden de USD 1–5 en total
- Athena: USD 5 por TB escaneado; con Parquet y particionado, las consultas típicas escanean menos de 50 MB

---

## 7. Registro de Decisiones

| Decisión | Alternativa considerada | Justificación |
|---|---|---|
| Formato Parquet en processed | CSV en processed | Menor costo en Athena, mejor rendimiento en consultas |
| Particionado por `year` | Sin particionado | Permite partition pruning y reduce datos escaneados |
| Un Job de Glue por archivo | Un único Job para los tres | Facilita mantenimiento, permite ejecución paralela y aísla errores |
| Un bucket con prefijos | Un bucket por capa | Simplifica permisos IAM y reduce overhead de configuración |
| Athena serverless | Redshift o RDS | Sin infraestructura fija, costo por consulta, integración nativa con S3 y Glue |

---

*Universidad EAFIT — Ingeniería de Sistemas — 2026-1*
