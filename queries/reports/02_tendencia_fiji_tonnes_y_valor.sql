-- Consulta 2: Evolución histórica de la ZEE de Fiyi (1950–2018)
-- Muestra simultáneamente el volumen de captura (tonnes) y el valor económico (landed_value),
-- lo que permite observar si la relación valor/tonelada cambió con el tiempo.
-- Fuente: tabla eez (Zona Económica Exclusiva de Fiyi)
SELECT
    CAST(year AS INT)           AS year,
    ROUND(SUM(tonnes), 2)       AS total_tonnes,
    ROUND(SUM(landed_value), 2) AS total_landed_value_usd,
    ROUND(
        SUM(landed_value) / NULLIF(SUM(tonnes), 0), 2
    )                           AS valor_por_tonelada_usd
FROM eez
GROUP BY year
ORDER BY CAST(year AS INT);
