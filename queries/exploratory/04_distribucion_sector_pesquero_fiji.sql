-- Distribución de capturas por sector pesquero (industrial vs subsistencia) en la ZEE de Fiyi
SELECT
    fishing_sector,
    ROUND(SUM(tonnes), 2) AS total_tonnes,
    ROUND(SUM(tonnes) * 100.0 / SUM(SUM(tonnes)) OVER (), 2) AS pct_tonnes
FROM eez
GROUP BY fishing_sector
ORDER BY total_tonnes DESC;
