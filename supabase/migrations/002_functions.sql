-- ============================================================
-- PienoAmico — Migration 002: Funzioni PostGIS
-- ============================================================

-- ============================================================
-- FUNZIONE: get_nearby_fuel
-- Trova distributori vicini con prezzi per un dato carburante.
-- Ottimizzata per < 300ms sul free tier Supabase.
--
-- Parametri:
--   p_lat, p_lon    : coordinate utente (WGS84)
--   p_raggio_m      : raggio ricerca in metri (default 5000)
--   p_carburante    : tipo carburante ('benzina','gasolio','gpl','metano','hvo')
--   p_is_self       : NULL=entrambi, TRUE=solo self, FALSE=solo servito
--   p_limit         : max risultati restituiti (default 30)
-- ============================================================

CREATE OR REPLACE FUNCTION get_nearby_fuel(
    p_lat         FLOAT,
    p_lon         FLOAT,
    p_raggio_m    INTEGER  DEFAULT 5000,
    p_carburante  TEXT     DEFAULT 'benzina',
    p_is_self     BOOLEAN  DEFAULT NULL,
    p_limit       INTEGER  DEFAULT 30
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
    SELECT
        d.id,
        d.nome,
        d.bandiera,
        d.indirizzo,
        d.comune,
        d.tipo_impianto,
        ST_Y(d.posizione::geometry)::FLOAT                                              AS latitudine,
        ST_X(d.posizione::geometry)::FLOAT                                              AS longitudine,
        ST_Distance(d.posizione, ST_MakePoint(p_lon, p_lat)::GEOGRAPHY)::INTEGER        AS distanza_m,

        -- Prezzo self-service più recente (NULL se non disponibile o stale)
        (
            SELECT p.prezzo
            FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
              AND p.is_self     = true
              AND p.dt_comunicazione > now() - INTERVAL '48 hours'
            LIMIT 1
        ) AS prezzo_self,

        -- Prezzo servito più recente (NULL se non disponibile o stale)
        (
            SELECT p.prezzo
            FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
              AND p.is_self     = false
              AND p.dt_comunicazione > now() - INTERVAL '48 hours'
            LIMIT 1
        ) AS prezzo_servito,

        -- Timestamp dell'aggiornamento più recente per questo carburante
        (
            SELECT MAX(p.dt_comunicazione)
            FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
              AND p.dt_comunicazione > now() - INTERVAL '48 hours'
        ) AS dt_aggiornamento

    FROM distributori d
    WHERE
        d.attivo = true
        AND ST_DWithin(
            d.posizione,
            ST_MakePoint(p_lon, p_lat)::GEOGRAPHY,
            p_raggio_m
        )
        -- Includi solo impianti con almeno un prezzo recente per questo carburante
        -- Questa condizione EXISTS viene valutata DOPO il filtro spaziale (molto efficiente)
        AND EXISTS (
            SELECT 1
            FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
              AND p.dt_comunicazione > now() - INTERVAL '48 hours'
              AND (p_is_self IS NULL OR p.is_self = p_is_self)
        )

    ORDER BY
        -- Ordina per prezzo minimo disponibile, poi distanza come tiebreaker
        COALESCE(
            (
                SELECT MIN(p.prezzo)
                FROM prezzi_correnti p
                WHERE p.id_impianto = d.id
                  AND p.carburante  = p_carburante::carburante_enum
                  AND p.dt_comunicazione > now() - INTERVAL '48 hours'
                  AND (p_is_self IS NULL OR p.is_self = p_is_self)
            ),
            9999
        ) ASC,
        ST_Distance(d.posizione, ST_MakePoint(p_lon, p_lat)::GEOGRAPHY) ASC

    LIMIT p_limit;
$$;
