-- Porcentaje de capturas reportadas vs no reportadas por fuente de datos
WITH combined AS (
    SELECT 'global'   AS fuente, reporting_status, tonnes FROM global
    UNION ALL
    SELECT 'highseas' AS fuente, reporting_status, tonnes FROM highseas
    UNION ALL
    SELECT 'eez'      AS fuente, reporting_status, tonnes FROM eez
)
SELECT
    fuente,
    reporting_status,
    ROUND(SUM(tonnes), 2) AS total_tonnes,
    ROUND(SUM(tonnes) * 100.0 / SUM(SUM(tonnes)) OVER (PARTITION BY fuente), 2) AS pct_tonnes
FROM combined
GROUP BY fuente, reporting_status
ORDER BY fuente, reporting_status;
