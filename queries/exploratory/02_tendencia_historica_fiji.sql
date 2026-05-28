-- Tendencia histórica de toneladas capturadas en la ZEE de Fiyi por año (1950–2018)
SELECT
    CAST(year AS INT) AS year,
    ROUND(SUM(tonnes), 2) AS total_tonnes
FROM eez
GROUP BY year
ORDER BY CAST(year AS INT);
