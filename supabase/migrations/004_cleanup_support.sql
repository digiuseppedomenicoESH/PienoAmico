-- ============================================================
-- PienoAmico — Migration 004: Indici per cleanup pipeline
-- ============================================================
-- Aggiunge indici su updated_at per rendere efficienti le query
-- di cleanup eseguite dopo ogni import (markInactiveDistributori
-- e cleanupPrezziStale in scripts/supabase_client.js).
--
-- Senza questi indici le DELETE/UPDATE userebbero un full table scan.
-- Con questi indici la complessità scende da O(n) a O(log n).
-- ============================================================

-- Indice per cleanup prezzi stale:
-- DELETE FROM prezzi_correnti WHERE updated_at < $runStartedAt
CREATE INDEX IF NOT EXISTS idx_prezzi_updated_at
    ON prezzi_correnti (updated_at);

-- Indice per mark inactive distributori:
-- UPDATE distributori SET attivo = false
--   WHERE updated_at < $runStartedAt AND attivo = true
-- Indice parziale: copre solo le righe attive (subset più piccolo, query più comune).
CREATE INDEX IF NOT EXISTS idx_distributori_updated_at_attivo
    ON distributori (updated_at)
    WHERE attivo = true;

COMMENT ON INDEX idx_prezzi_updated_at IS
    'Supporta DELETE stale prezzi dopo ogni import MIMIT (scripts/supabase_client.js)';

COMMENT ON INDEX idx_distributori_updated_at_attivo IS
    'Supporta UPDATE attivo=false su stazioni rimosse da CSV MIMIT (scripts/supabase_client.js)';
