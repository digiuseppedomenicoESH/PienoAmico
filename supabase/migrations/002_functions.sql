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

        -- Prezzo self-service: nessun filtro su dt_comunicazione perché il gestore
        -- comunica solo quando cambia il prezzo (può restare invariato per settimane).
        -- La garanzia di freschezza è updated_at: se la riga è in prezzi_correnti,
        -- era presente nell'ultimo CSV MIMIT importato.
        (
            SELECT p.prezzo
            FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
              AND p.is_self     = true
            LIMIT 1
        ) AS prezzo_self,

        -- Prezzo servito
        (
            SELECT p.prezzo
            FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
              AND p.is_self     = false
            LIMIT 1
        ) AS prezzo_servito,

        -- Data in cui il gestore ha comunicato l'ultimo aggiornamento di prezzo
        (
            SELECT MAX(p.dt_comunicazione)
            FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
        ) AS dt_aggiornamento

    FROM distributori d
    WHERE
        d.attivo = true
        AND ST_DWithin(
            d.posizione,
            ST_MakePoint(p_lon, p_lat)::GEOGRAPHY,
            p_raggio_m
        )
        -- Includi solo impianti che hanno almeno un prezzo per questo carburante.
        -- La pulizia dei prezzi obsoleti è delegata a cleanupPrezziStale nello script
        -- di import, che rimuove le righe non presenti nell'ultimo CSV MIMIT.
        AND EXISTS (
            SELECT 1
            FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
              AND (p_is_self IS NULL OR p.is_self = p_is_self)
        )

    ORDER BY
        COALESCE(
            (
                SELECT MIN(p.prezzo)
                FROM prezzi_correnti p
                WHERE p.id_impianto = d.id
                  AND p.carburante  = p_carburante::carburante_enum
                  AND (p_is_self IS NULL OR p.is_self = p_is_self)
            ),
            9999
        ) ASC,
        ST_Distance(d.posizione, ST_MakePoint(p_lon, p_lat)::GEOGRAPHY) ASC

    LIMIT p_limit;
$$;
