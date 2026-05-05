-- ============================================================
-- PienoAmico — Migration 003: Row Level Security
-- ============================================================
-- Strategia:
--   - Utente 'anon' (app Flutter): solo SELECT
--   - Utente 'service_role' (GitHub Actions): SELECT + INSERT + UPDATE + DELETE
--   - Nessuna scrittura possibile dall'app mobile
-- ============================================================

-- Abilita RLS
ALTER TABLE distributori    ENABLE ROW LEVEL SECURITY;
ALTER TABLE prezzi_correnti ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- POLICY: Lettura pubblica (anonima)
-- L'app Flutter usa la ANON_KEY — può solo leggere
-- ============================================================

DROP POLICY IF EXISTS "anon_read_distributori"    ON distributori;
DROP POLICY IF EXISTS "anon_read_prezzi_correnti" ON prezzi_correnti;

CREATE POLICY "anon_read_distributori"
    ON distributori
    FOR SELECT
    TO anon
    USING (true);

CREATE POLICY "anon_read_prezzi_correnti"
    ON prezzi_correnti
    FOR SELECT
    TO anon
    USING (true);

-- ============================================================
-- NOTA: il ruolo 'service_role' bypassa RLS per default in Supabase.
-- Lo script Node.js (GitHub Actions) usa la SERVICE_KEY che mappa
-- su service_role → può scrivere senza policy aggiuntive.
-- NON aggiungere policy di scrittura per 'anon' o 'authenticated'.
-- ============================================================
