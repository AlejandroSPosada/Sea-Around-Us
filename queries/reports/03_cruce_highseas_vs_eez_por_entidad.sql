-- Consulta 3: Cruce entre Alta Mar (Pacífico Central Occidental) y ZEE de Fiyi
-- Identifica qué entidades pesqueras operan en AMBAS áreas y compara su volumen
-- de captura en cada zona. Permite ver quién domina la pesca en esta región del Pacífico.
-- Fuentes: tablas highseas y eez

WITH capturas_highseas AS (
    SELECT
        fishing_entity,
        ROUND(SUM(tonnes), 2) AS tonnes_highseas
    FROM highseas
    GROUP BY fishing_entity
),
capturas_eez AS (
    SELECT
        country                   AS fishing_entity,  -- eez usa `country`, lo renombramos para el JOIN
        ROUND(SUM(tonnes), 2)     AS tonnes_eez
    FROM eez
    GROUP BY country
)
SELECT
    COALESCE(h.fishing_entity, e.fishing_entity) AS fishing_entity,
    COALESCE(h.tonnes_highseas, 0)               AS tonnes_alta_mar,
    COALESCE(e.tonnes_eez, 0)                    AS tonnes_zee_fiyi,
    ROUND(
        COALESCE(h.tonnes_highseas, 0) + COALESCE(e.tonnes_eez, 0), 2
    )                                            AS total_region_pacifico
FROM capturas_highseas h
FULL OUTER JOIN capturas_eez e
    ON h.fishing_entity = e.fishing_entity
ORDER BY total_region_pacifico DESC;
