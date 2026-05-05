-- ============================================================
-- PienoAmico — Migration 001: Schema, Tabelle e Indici
-- ============================================================

-- Estensioni
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================================
-- ENUM TYPES
-- ============================================================

DROP TYPE IF EXISTS tipo_impianto_enum CASCADE;
CREATE TYPE tipo_impianto_enum AS ENUM ('stradale', 'autostradale');

DROP TYPE IF EXISTS carburante_enum CASCADE;
CREATE TYPE carburante_enum AS ENUM (
    'benzina',
    'gasolio',
    'gpl',
    'metano',
    'hvo',
    'altro'
);

-- ============================================================
-- TABELLA: distributori
-- Anagrafica impianti attivi (sorgente: anagrafica_impianti_attivi.csv)
-- ============================================================

DROP TABLE IF EXISTS distributori CASCADE;

CREATE TABLE distributori (
    id              INTEGER         PRIMARY KEY,   -- idImpianto MIMIT
    gestore         VARCHAR(200),
    bandiera        VARCHAR(100),
    tipo_impianto   tipo_impianto_enum NOT NULL DEFAULT 'stradale',
    nome            VARCHAR(200),
    indirizzo       VARCHAR(300),
    comune          VARCHAR(100),
    provincia       CHAR(2),
    posizione       GEOGRAPHY(POINT, 4326) NOT NULL,
    attivo          BOOLEAN         NOT NULL DEFAULT true,
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON COLUMN distributori.posizione IS 'Coordinate WGS84 come GEOGRAPHY per distanze in metri';
COMMENT ON COLUMN distributori.attivo    IS 'false = impianto rimosso dal CSV MIMIT ma conservato per integrità referenziale';

-- Indice spaziale — cuore delle query geografiche
CREATE INDEX idx_distributori_posizione
    ON distributori USING GIST (posizione);

-- Indice per filtro provincia (future feature: ricerca per zona)
CREATE INDEX idx_distributori_provincia
    ON distributori (provincia);

-- Indice parziale per impianti autostradali (subset piccolo, query dedicata)
CREATE INDEX idx_distributori_autostradale
    ON distributori (tipo_impianto)
    WHERE tipo_impianto = 'autostradale';

-- ============================================================
-- TABELLA: prezzi_correnti
-- Ultimo prezzo comunicato per (impianto, carburante, modalità)
-- NON è una tabella storica — contiene solo il valore più recente
-- ============================================================

DROP TABLE IF EXISTS prezzi_correnti CASCADE;

CREATE TABLE prezzi_correnti (
    id_impianto         INTEGER             NOT NULL REFERENCES distributori(id) ON DELETE CASCADE,
    carburante          carburante_enum     NOT NULL,
    is_self             BOOLEAN             NOT NULL,
    prezzo              NUMERIC(5,3)        NOT NULL,
    dt_comunicazione    TIMESTAMPTZ         NOT NULL,
    updated_at          TIMESTAMPTZ         NOT NULL DEFAULT now(),

    PRIMARY KEY (id_impianto, carburante, is_self)
);

COMMENT ON TABLE  prezzi_correnti IS 'Una riga per (impianto, carburante, modalità). Aggiornata via upsert dal script MIMIT.';
COMMENT ON COLUMN prezzi_correnti.dt_comunicazione IS 'Timestamp originale della comunicazione dal gestore al MIMIT';

-- Indice per ricerche per carburante ordinate per prezzo (query più frequente)
CREATE INDEX idx_prezzi_carburante_prezzo
    ON prezzi_correnti (carburante, prezzo ASC);

-- Indice per escludere prezzi stale (> 48h)
CREATE INDEX idx_prezzi_dt_comunicazione
    ON prezzi_correnti (dt_comunicazione DESC);

-- Indice parziale self-service (metà delle query tipiche)
CREATE INDEX idx_prezzi_self
    ON prezzi_correnti (carburante, prezzo ASC)
    WHERE is_self = true;

-- Indice parziale servito
CREATE INDEX idx_prezzi_servito
    ON prezzi_correnti (carburante, prezzo ASC)
    WHERE is_self = false;
