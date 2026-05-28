-- Evolución del valor económico total (landed_value en USD 2010) por año en el dataset global
SELECT
    CAST(year AS INT) AS year,
    ROUND(SUM(landed_value), 2) AS total_landed_value
FROM global
GROUP BY year
ORDER BY CAST(year AS INT);
