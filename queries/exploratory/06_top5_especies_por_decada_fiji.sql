-- Top 5 especies más capturadas por década en la ZEE de Fiyi
WITH por_decada AS (
    SELECT
        (CAST(year AS INT) / 10) * 10 AS decada,
        scientific_name,
        ROUND(SUM(tonnes), 2) AS total_tonnes
    FROM eez
    GROUP BY (CAST(year AS INT) / 10) * 10, scientific_name
),
ranked AS (
    SELECT
        decada,
        scientific_name,
        total_tonnes,
        ROW_NUMBER() OVER (PARTITION BY decada ORDER BY total_tonnes DESC) AS rn
    FROM por_decada
)
SELECT
    decada,
    scientific_name,
    total_tonnes
FROM ranked
WHERE rn <= 5
ORDER BY decada, total_tonnes DESC;
