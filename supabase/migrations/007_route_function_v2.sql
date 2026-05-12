-- ============================================================
-- PienoAmico — Migration 007: Aggiornamento get_fuel_along_route
-- Ordine per posizione lungo il percorso (non per prezzo).
-- distanza_m ora = distanza dal punto di partenza lungo la route.
-- ============================================================

CREATE OR REPLACE FUNCTION get_fuel_along_route(
    p_waypoints   JSONB,
    p_carburante  TEXT     DEFAULT 'benzina',
    p_buffer_m    INTEGER  DEFAULT 15000,
    p_limit       INTEGER  DEFAULT 25
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
    distanza_m          INTEGER,   -- distanza dal punto di partenza lungo la route
    prezzo_self         NUMERIC,
    prezzo_servito      NUMERIC,
    dt_aggiornamento    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
PARALLEL SAFE
AS $$
    WITH route AS (
        SELECT
            -- SRID 4326 esplicito per compatibilità con ST_LineLocatePoint
            ST_SetSRID(
                ST_MakeLine(
                    ARRAY(
                        SELECT ST_MakePoint(
                            (wp ->> 1)::FLOAT,
                            (wp ->> 0)::FLOAT
                        )
                        FROM jsonb_array_elements(p_waypoints) AS wp
                    )
                ),
            4326) AS linegeom,
            ST_MakeLine(
                ARRAY(
                    SELECT ST_MakePoint(
                        (wp ->> 1)::FLOAT,
                        (wp ->> 0)::FLOAT
                    )
                    FROM jsonb_array_elements(p_waypoints) AS wp
                )
            )::GEOGRAPHY AS linestring
    )
    SELECT
        d.id,
        d.nome,
        d.bandiera,
        d.indirizzo,
        d.comune,
        d.tipo_impianto,
        ST_Y(d.posizione::geometry)::FLOAT                              AS latitudine,
        ST_X(d.posizione::geometry)::FLOAT                              AS longitudine,
        -- Distanza dal punto di partenza lungo la polyline (in metri)
        (
            ST_LineLocatePoint(route.linegeom, d.posizione::geometry)
            * ST_Length(route.linestring)
        )::INTEGER                                                       AS distanza_m,
        (
            SELECT p.prezzo FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
              AND p.is_self     = true
            LIMIT 1
        ) AS prezzo_self,
        (
            SELECT p.prezzo FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
              AND p.is_self     = false
            LIMIT 1
        ) AS prezzo_servito,
        (
            SELECT MAX(p.dt_comunicazione) FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
        ) AS dt_aggiornamento

    FROM distributori d, route
    WHERE
        d.attivo = true
        AND ST_DWithin(d.posizione, route.linestring, p_buffer_m)
        AND EXISTS (
            SELECT 1 FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
        )
    -- Ordine: prima stazione che incontri → ultima
    ORDER BY
        ST_LineLocatePoint(route.linegeom, d.posizione::geometry) ASC
    LIMIT p_limit;
$$;
