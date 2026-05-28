-- Comparación de capturas: Alta Mar (Pacífico Central Occidental) vs ZEE de Fiyi por año
SELECT
    'Alta Mar' AS fuente,
    CAST(year AS INT) AS year,
    ROUND(SUM(tonnes), 2) AS total_tonnes
FROM highseas
GROUP BY year

UNION ALL

SELECT
    'ZEE Fiyi' AS fuente,
    CAST(year AS INT) AS year,
    ROUND(SUM(tonnes), 2) AS total_tonnes
FROM eez
GROUP BY year

ORDER BY year, fuente;
