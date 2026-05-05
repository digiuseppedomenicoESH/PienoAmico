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
