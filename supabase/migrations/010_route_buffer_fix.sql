-- ============================================================
-- PienoAmico — Migration 010: fix buffer percorso + deviazione_m
--
-- Problemi risolti rispetto alla 009:
--   • p_buffer_m default ridotto da 20000 a 1500 m
--     (20km includeva città lontane; su strade non-autostrada 3km era già
--      una deviazione eccessiva; 1500m copre aree di servizio e stazioni
--      a bordo strada senza portare l'utente km fuori percorso)
--   • Aggiunta colonna deviazione_m: distanza perpendicolare reale
--     dal distributore al percorso, così l'UI può segnalare deviazioni
-- ============================================================

DROP FUNCTION IF EXISTS get_fuel_along_route(jsonb, text, integer, integer);

CREATE OR REPLACE FUNCTION get_fuel_along_route(
    p_waypoints   JSONB,
    p_carburante  TEXT     DEFAULT 'benzina',
    p_buffer_m    INTEGER  DEFAULT 1500,
    p_zone_count  INTEGER  DEFAULT 8
)
RETURNS TABLE (
    id                  INTEGER,
    nome                VARCHAR,
    bandiera            VARCHAR,
    indirizzo           VARCHAR,
    comune              VARCHAR,
    tipo_impianto       tipo_impianto_enum,
    latitudine          FLOAT,
    longitudine         FLOAT,
    distanza_m          INTEGER,
    deviazione_m        INTEGER,
    prezzo_self         NUMERIC,
    prezzo_servito      NUMERIC,
    dt_aggiornamento    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    WITH route AS (
        SELECT
            ST_SetSRID(geom, 4326)              AS linegeom,
            ST_SetSRID(geom, 4326)::GEOGRAPHY   AS linestring
        FROM (
            SELECT ST_MakeLine(ARRAY(
                SELECT ST_MakePoint((wp ->> 1)::FLOAT, (wp ->> 0)::FLOAT)
                FROM jsonb_array_elements(p_waypoints) AS wp
            )) AS geom
        ) raw
    ),
    located AS (
        SELECT
            d.id,
            d.nome,
            d.bandiera,
            d.indirizzo,
            d.comune,
            d.tipo_impianto,
            ST_Y(d.posizione::geometry)::FLOAT                              AS lat,
            ST_X(d.posizione::geometry)::FLOAT                              AS lon,
            ST_LineLocatePoint(r.linegeom, d.posizione::geometry)           AS fraction,
            ST_Distance(d.posizione, r.linestring)::INTEGER                 AS dev_m
        FROM distributori d, route r
        WHERE
            d.attivo = true
            AND ST_DWithin(d.posizione, r.linestring, p_buffer_m)
            AND EXISTS (
                SELECT 1 FROM prezzi_correnti p
                WHERE p.id_impianto = d.id
                  AND p.carburante  = p_carburante::carburante_enum
            )
    ),
    candidates AS (
        SELECT
            l.id,
            l.nome,
            l.bandiera,
            l.indirizzo,
            l.comune,
            l.tipo_impianto,
            l.lat,
            l.lon,
            l.fraction,
            l.dev_m,
            (l.fraction * ST_Length(r.linestring))::INTEGER                AS dist_m,
            (SELECT p.prezzo FROM prezzi_correnti p
             WHERE p.id_impianto = l.id AND p.carburante = p_carburante::carburante_enum
               AND p.is_self = true  LIMIT 1)                              AS p_self,
            (SELECT p.prezzo FROM prezzi_correnti p
             WHERE p.id_impianto = l.id AND p.carburante = p_carburante::carburante_enum
               AND p.is_self = false LIMIT 1)                              AS p_servito,
            (SELECT MAX(p.dt_comunicazione) FROM prezzi_correnti p
             WHERE p.id_impianto = l.id AND p.carburante = p_carburante::carburante_enum) AS dt_agg
        FROM located l, route r
    ),
    best_per_zone AS (
        SELECT DISTINCT ON (LEAST(floor(c.fraction * p_zone_count)::INTEGER, p_zone_count - 1))
            c.id, c.nome, c.bandiera, c.indirizzo, c.comune, c.tipo_impianto,
            c.lat, c.lon, c.dist_m, c.dev_m, c.p_self, c.p_servito, c.dt_agg,
            LEAST(floor(c.fraction * p_zone_count)::INTEGER, p_zone_count - 1) AS zone_idx
        FROM candidates c
        ORDER BY
            LEAST(floor(c.fraction * p_zone_count)::INTEGER, p_zone_count - 1) ASC,
            COALESCE(c.p_self, c.p_servito) ASC NULLS LAST
    )
    SELECT
        bpz.id,
        bpz.nome,
        bpz.bandiera,
        bpz.indirizzo,
        bpz.comune,
        bpz.tipo_impianto,
        bpz.lat       AS latitudine,
        bpz.lon       AS longitudine,
        bpz.dist_m    AS distanza_m,
        bpz.dev_m     AS deviazione_m,
        bpz.p_self    AS prezzo_self,
        bpz.p_servito AS prezzo_servito,
        bpz.dt_agg    AS dt_aggiornamento
    FROM best_per_zone bpz
    ORDER BY bpz.zone_idx ASC;
$$;
