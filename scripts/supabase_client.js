// Singleton Supabase client per gli script Node.js.
// Usa la SERVICE_KEY (letta da env) — mai usare la ANON_KEY negli script.

import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_KEY;

if (!url || !key) {
  throw new Error('SUPABASE_URL e SUPABASE_SERVICE_KEY devono essere definiti nelle variabili d\'ambiente');
}

export const supabase = createClient(url, key, {
  auth: { persistSession: false },
});

// Soglie di sicurezza: sotto questi valori il cleanup non viene eseguito.
// Proteggono da download parziali o errori MIMIT che restituiscono CSV vuoti/troncati.
const SOGLIA_MIN_DISTRIBUTORI = 10_000;
const SOGLIA_MIN_PREZZI        = 50_000;

/**
 * Esegue upsert in batch con chunk per non superare i limiti Supabase free tier.
 * @param {string} table       - Nome tabella
 * @param {Array}  rows        - Righe da inserire/aggiornare
 * @param {number} chunkSize   - Righe per richiesta HTTP
 * @returns {{ inserted: number, errors: number }}
 */
export async function batchUpsert(table, rows, chunkSize = 500) {
  let inserted = 0;
  let errors = 0;

  for (let i = 0; i < rows.length; i += chunkSize) {
    const chunk = rows.slice(i, i + chunkSize);
    const { error } = await supabase.from(table).upsert(chunk);

    if (error) {
      console.error(JSON.stringify({ event: 'upsert_error', table, chunk_start: i, error: error.message }));
      errors += chunk.length;
    } else {
      inserted += chunk.length;
    }
  }

  return { inserted, errors };
}

/**
 * Marca come inattivi i distributori non presenti nell'ultimo import.
 *
 * Logica: ogni riga upsertata in questo run ha updated_at >= runStartedAt.
 * Le righe con updated_at < runStartedAt non erano nel CSV corrente → chiuse/rimosse da MIMIT.
 *
 * Sicurezza: eseguita solo se l'import ha superato SOGLIA_MIN_DISTRIBUTORI righe,
 * per evitare di marcare tutto inattivo in caso di download fallito/parziale.
 *
 * @param {string} runStartedAt  - ISO timestamp registrato PRIMA del fetch del CSV
 * @param {number} upsertedCount - Righe effettivamente inserite/aggiornate in questo run
 * @returns {{ marked: number, skipped: boolean }}
 */
export async function markInactiveDistributori(runStartedAt, upsertedCount) {
  if (upsertedCount < SOGLIA_MIN_DISTRIBUTORI) {
    console.log(JSON.stringify({
      event:     'skip_mark_inactive',
      reason:    'count_below_threshold',
      count:     upsertedCount,
      threshold: SOGLIA_MIN_DISTRIBUTORI,
    }));
    return { marked: 0, skipped: true };
  }

  // Prima conta quanti verranno marcati (per logging)
  const { count: toMark, error: countErr } = await supabase
    .from('distributori')
    .select('id', { count: 'exact', head: true })
    .lt('updated_at', runStartedAt)
    .eq('attivo', true);

  if (countErr) {
    console.error(JSON.stringify({ event: 'mark_inactive_count_error', error: countErr.message }));
  }

  const { error } = await supabase
    .from('distributori')
    .update({ attivo: false })
    .lt('updated_at', runStartedAt)
    .eq('attivo', true);

  if (error) {
    console.error(JSON.stringify({ event: 'mark_inactive_error', error: error.message }));
    return { marked: 0, skipped: false, error: error.message };
  }

  return { marked: toMark ?? 0, skipped: false };
}

/**
 * Elimina da prezzi_correnti le righe non aggiornate nell'ultimo import.
 *
 * Logica identica a markInactiveDistributori: ogni riga upsertata ha
 * updated_at >= runStartedAt. Le righe più vecchie appartengono a stazioni
 * che non compaiono più nel CSV MIMIT (chiuse, non comunicano, cambio gestore).
 *
 * Sicurezza: eseguita solo se l'import ha superato SOGLIA_MIN_PREZZI righe.
 *
 * @param {string} runStartedAt  - ISO timestamp registrato PRIMA del fetch del CSV
 * @param {number} upsertedCount - Righe effettivamente inserite/aggiornate in questo run
 * @returns {{ deleted: number, skipped: boolean }}
 */
export async function cleanupPrezziStale(runStartedAt, upsertedCount) {
  if (upsertedCount < SOGLIA_MIN_PREZZI) {
    console.log(JSON.stringify({
      event:     'skip_cleanup_prezzi',
      reason:    'count_below_threshold',
      count:     upsertedCount,
      threshold: SOGLIA_MIN_PREZZI,
    }));
    return { deleted: 0, skipped: true };
  }

  // Conta prima per logging
  const { count: toDelete, error: countErr } = await supabase
    .from('prezzi_correnti')
    .select('id_impianto', { count: 'exact', head: true })
    .lt('updated_at', runStartedAt);

  if (countErr) {
    console.error(JSON.stringify({ event: 'cleanup_prezzi_count_error', error: countErr.message }));
  }

  const { error } = await supabase
    .from('prezzi_correnti')
    .delete()
    .lt('updated_at', runStartedAt);

  if (error) {
    console.error(JSON.stringify({ event: 'cleanup_prezzi_error', error: error.message }));
    return { deleted: 0, skipped: false, error: error.message };
  }

  return { deleted: toDelete ?? 0, skipped: false };
}
