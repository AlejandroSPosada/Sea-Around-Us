-- Top 10 entidades pesqueras con mayor captura total (toneladas) en el dataset global
SELECT
    fishing_entity,
    ROUND(SUM(tonnes), 2) AS total_tonnes
FROM global
GROUP BY fishing_entity
ORDER BY total_tonnes DESC
LIMIT 10;
