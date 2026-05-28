# The Sea Around Us — Infraestructura de Datos en la Nube

**Sistemas Intensivos en Datos — 2026-1 — Universidad EAFIT**

> Pipeline de ingestión, transformación y análisis de datos históricos de capturas pesqueras globales (1950–2018), implementado sobre AWS con los servicios S3, Glue y Athena.

---

## Descripción del Proyecto

The Sea Around Us es un proyecto de investigación global con sede en la Universidad de British Columbia (UBC) que recopila, analiza y difunde información científica sobre las pesquerías y los ecosistemas marinos del mundo. Este repositorio implementa una infraestructura de datos en la nube sobre AWS para analizar tres conjuntos de datos de ese proyecto: capturas en alta mar a nivel global, capturas en el Pacífico Central Occidental, y capturas en la Zona Económica Exclusiva (ZEE) de Fiyi.

El objetivo es construir un pipeline completo de ingestión, transformación, catalogación y análisis que sirva como base para generar reportes sobre el impacto de la pesca en aguas internacionales y Zonas Económicas Exclusivas.

---

## Equipo

| Nombre                  | Responsabilidad principal                |
| ----------------------- | ---------------------------------------- |
| Alejandro Sepúlveda     | Infraestructura S3 e ingestión de datos  |
| Samuel Aristizabal      | ETL, limpieza y catálogo de datos (Glue) |
| Gabriela Lucía Martínez | Consultas Athena y capa de visualización |

---

## Fuentes de Datos

Los tres archivos CSV provienen del sitio oficial de The Sea Around Us (seaaroundus.org):

| Archivo                     | Descripción                                                 |
| --------------------------- | ----------------------------------------------------------- |
| `SAU-GLOBAL-1-v48-0.csv`    | Capturas en todas las áreas de alta mar del mundo           |
| `SAU-HighSeas-71-v48-0.csv` | Capturas en el Pacífico Central Occidental (próxima a Fiyi) |
| `SAU-EEZ-242-v48-0.csv`     | Capturas en la Zona Económica Exclusiva de Fiyi             |

### Esquemas

**SAU-EEZ-242** (ZEE de Fiyi)

```
area_name, area_type, data_layer, uncertainty_score, year, scientific_name,
fish_name, functional_group, commercial_group, country, fishing_sector,
catch_type, reporting_status, gear_type, end_use_type, tonnes, landed_value
```

**SAU-GLOBAL-1** (Alta mar global)

```
year, fishing_entity, fishing_sector, catch_type, reporting_status,
gear_type, end_use_type, tonnes, landed_value
```

**SAU-HighSeas-71** (Pacífico Central Occidental)

```
area_name, area_type, year, scientific_name, common_name, functional_group,
commercial_group, fishing_entity, fishing_sector, catch_type, reporting_status,
gear_type, end_use_type, tonnes, landed_value
```

---

## Arquitectura

```
CSV locales
    |
    v
Amazon S3 — capa raw
    |  s3://bucket/raw/{global, highseas, eez}/
    v
AWS Glue Jobs — limpieza y transformación
    |  Normalización de columnas, tipado, manejo de nulos
    v
Amazon S3 — capa processed
    |  Formato Parquet, particionado por year
    v
AWS Glue Data Catalog
    |  Esquemas inferidos por Crawlers
    v
Amazon Athena
    |  Consultas SQL serverless sobre S3
    v
Visualizaciones y reportes analíticos
```

---

## Servicios AWS Utilizados

- **Amazon S3** — Almacenamiento de datos crudos y procesados
- **AWS Glue** — Jobs ETL y Crawlers para catalogación
- **AWS Glue Data Catalog** — Catálogo de metadatos y esquemas
- **Amazon Athena** — Consultas SQL serverless sobre los datos en S3

---

## Estructura del Repositorio

```
.
├── README.md
├── TODO.md
├── data/
│   └── raw/                    # CSVs originales descargados de The Sea Around Us
├── infra/
│   ├── s3/                     # Scripts de configuración de buckets e IAM
│   └── glue/                   # Definiciones de Jobs y Crawlers de Glue
├── etl/
│   ├── clean_global.py         # Limpieza del archivo de alta mar global
│   ├── clean_highseas.py       # Limpieza del archivo del Pacífico Central Occidental
│   └── clean_eez.py            # Limpieza del archivo ZEE Fiyi
├── queries/
│   ├── exploratory/            # Consultas Athena de análisis exploratorio
│   └── reports/                # Consultas para informes finales
├── viz/
│   └── dashboard_notes.md      # Diseño y notas de visualizaciones
└── docs/
    └── architecture.md         # Diagrama y decisiones de arquitectura
```

---

## Instrucciones de Despliegue

### Prerrequisitos

- Cuenta AWS con permisos sobre S3, Glue y Athena
- AWS CLI configurado (`aws configure`)
- Python 3.9+ con `boto3` instalado

### 1. Carga de datos a S3

```bash
aws s3 cp data/raw/SAU-GLOBAL-1-v48-0.csv     s3://<bucket>/raw/global/
aws s3 cp data/raw/SAU-HighSeas-71-v48-0.csv  s3://<bucket>/raw/highseas/
aws s3 cp data/raw/SAU-EEZ-242-v48-0.csv      s3://<bucket>/raw/eez/
```

### 2. Ejecutar Jobs de Glue

Desde la consola de AWS Glue o mediante CLI, ejecutar los jobs en el orden: `clean_global → clean_highseas → clean_eez`.

### 3. Correr los Crawlers

Ejecutar los Crawlers para que detecten el esquema de los datos procesados y actualicen el Data Catalog.

### 4. Consultas en Athena

Abrir Amazon Athena, seleccionar la base de datos del catálogo (`seaaroundus_db`) y ejecutar las consultas de `queries/exploratory/`.

---

## Consultas Planificadas

- Top 10 entidades pesqueras con mayor captura (toneladas) por año
- Tendencia histórica de capturas en la ZEE de Fiyi (1950–2018)
- Comparación de capturas en alta mar vs. ZEE para la región del Pacífico Central Occidental
- Distribución por sector de pesca: industrial vs. subsistencia
- Porcentaje de capturas reportadas vs. no reportadas por fuente
- Top 5 especies más capturadas por década en la ZEE de Fiyi
- Evolución del valor económico total por año en el dataset global

---

## Escalabilidad

La solución está diseñada para escalar al dataset completo de The Sea Around Us (todas las regiones oceánicas, 1950–2018). Las decisiones clave que lo permiten son:

- **Formato Parquet** en la capa procesada: compresión eficiente y lectura columnar
- **Particionado por `year`** en S3: Athena escanea únicamente las particiones relevantes
- **Glue serverless**: escala automáticamente con el volumen de datos
- **Athena pay-per-query**: sin costos fijos de infraestructura de cómputo

---

*Universidad EAFIT — Ingeniería de Sistemas — 2026-1*
