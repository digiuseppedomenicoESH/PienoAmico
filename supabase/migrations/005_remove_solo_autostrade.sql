-- ============================================================
-- PienoAmico — Migration 005: rimozione filtro "solo autostrade"
-- Filtro rimosso: il dataset MIMIT ha pochissimi impianti
-- autostradali geolocalizzati correttamente, il filtro non era
-- utile in pratica.
-- Droppa l'eventuale versione a 7 parametri introdotta in una
-- migration precedente; la versione a 6 parametri di 002 resta.
-- ============================================================

DROP FUNCTION IF EXISTS get_nearby_fuel(
    FLOAT,
    FLOAT,
    INTEGER,
    TEXT,
    BOOLEAN,
    INTEGER,
    BOOLEAN
);
