-- ============================================================
-- PienoAmico — Migration 006: Funzione ricerca lungo percorso
-- ============================================================

-- ============================================================
-- FUNZIONE: get_fuel_along_route
-- Trova distributori entro p_buffer_m da una polyline di percorso.
-- I waypoints arrivano come JSONB array di [lat, lon].
--
-- Parametri:
--   p_waypoints  : [[lat,lon], [lat,lon], ...] — punti del percorso
--   p_carburante : tipo carburante
--   p_buffer_m   : buffer in metri attorno alla polyline (default 15000)
--   p_limit      : max risultati (default 20)
--
-- Nota: distanza_m qui è la distanza perpendicolare dalla polyline,
-- non dalla posizione utente. Valore ~0 = stazione sulla strada.
-- ============================================================

CREATE OR REPLACE FUNCTION get_fuel_along_route(
    p_waypoints   JSONB,
    p_carburante  TEXT     DEFAULT 'benzina',
    p_buffer_m    INTEGER  DEFAULT 15000,
    p_limit       INTEGER  DEFAULT 20
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
    prezzo_self         NUMERIC,
    prezzo_servito      NUMERIC,
    dt_aggiornamento    TIMESTAMPTZ
)
LANGUAGE sql
STABLE
PARALLEL SAFE
AS $$
    WITH route AS (
        SELECT ST_MakeLine(
            ARRAY(
                SELECT ST_MakePoint(
                    (wp ->> 1)::FLOAT,  -- longitudine (indice 1)
                    (wp ->> 0)::FLOAT   -- latitudine  (indice 0)
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
        ST_Y(d.posizione::geometry)::FLOAT                          AS latitudine,
        ST_X(d.posizione::geometry)::FLOAT                          AS longitudine,
        ST_Distance(d.posizione, route.linestring)::INTEGER         AS distanza_m,
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
    ORDER BY
        COALESCE(
            (
                SELECT MIN(p.prezzo) FROM prezzi_correnti p
                WHERE p.id_impianto = d.id
                  AND p.carburante  = p_carburante::carburante_enum
            ),
            9999
        ) ASC,
        ST_Distance(d.posizione, route.linestring) ASC
    LIMIT p_limit;
$$;
