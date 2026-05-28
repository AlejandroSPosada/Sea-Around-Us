-- Consulta 1: Top 10 entidades pesqueras por captura total en el dataset global
-- Incluye valor económico (USD 2010) para contextualizar el impacto comercial.
-- Fuente: tabla global (todas las áreas de mar abierto del mundo, 1950–2018)
SELECT
    fishing_entity,
    ROUND(SUM(tonnes), 2)       AS total_tonnes,
    ROUND(SUM(landed_value), 2) AS total_landed_value_usd,
    ROUND(
        SUM(tonnes) * 100.0 / SUM(SUM(tonnes)) OVER (), 2
    )                           AS pct_captura_global
FROM global
GROUP BY fishing_entity
ORDER BY total_tonnes DESC
LIMIT 10;
