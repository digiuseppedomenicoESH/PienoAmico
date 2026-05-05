// Entry point pipeline importazione dati MIMIT → Supabase.
// Eseguito da GitHub Actions due volte al giorno (08:30 e 14:30 ora italiana).

import 'dotenv/config';
import { batchUpsert, markInactiveDistributori, cleanupPrezziStale } from './supabase_client.js';
import { parseAnagrafica } from './parsers/anagrafica.js';
import { parsePrezzi } from './parsers/prezzi.js';

const MIMIT_ANAGRAFICA_URL = 'https://www.mimit.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv';
const MIMIT_PREZZI_URL     = 'https://www.mimit.gov.it/images/exportCSV/prezzo_alle_8.csv';

const DRY_RUN = process.env.DRY_RUN === 'true';

async function fetchCsv(url) {
  const res = await fetch(url, {
    headers: { 'Accept-Encoding': 'gzip, deflate' },
    signal: AbortSignal.timeout(30_000),
  });

  if (!res.ok) {
    throw new Error(`HTTP ${res.status} scaricando ${url}`);
  }

  return res.text();
}

async function run() {
  const startedAt = Date.now();

  // Timestamp registrato PRIMA di qualsiasi fetch.
  // Le righe upsertate in questo run avranno updated_at >= runStartedAt
  // (il fetch dura almeno qualche secondo, quindi il clock avanza).
  // Le righe con updated_at < runStartedAt non erano nel CSV corrente → da pulire.
  const runStartedAt = new Date().toISOString();

  console.log(JSON.stringify({ event: 'import_start', dry_run: DRY_RUN, run_started_at: runStartedAt }));

  // ── Step 1: Anagrafica ───────────────────────────────────────────────────
  console.log(JSON.stringify({ event: 'fetch_anagrafica_start' }));
  const anagraficaCsv = await fetchCsv(MIMIT_ANAGRAFICA_URL);
  const distributori  = await parseAnagrafica(anagraficaCsv);
  console.log(JSON.stringify({ event: 'fetch_anagrafica_done', count: distributori.length }));

  let d_ins = 0;
  if (!DRY_RUN) {
    const { inserted, errors: d_err } = await batchUpsert('distributori', distributori, 500);
    d_ins = inserted;
    console.log(JSON.stringify({ event: 'upsert_distributori', inserted, errors: d_err }));

    // Marca inattivi i distributori non più presenti nel CSV MIMIT.
    // Sicuro solo se abbiamo importato abbastanza righe (soglia 10.000).
    const { marked, skipped, error: markErr } = await markInactiveDistributori(runStartedAt, d_ins);
    console.log(JSON.stringify({
      event:   'mark_inactive_distributori',
      marked,
      skipped,
      ...(markErr && { error: markErr }),
    }));
  }

  // ── Step 2: Prezzi ───────────────────────────────────────────────────────
  // Costruiamo un Set degli ID distributori validi per filtrare prezzi orfani.
  const idValidi = new Set(distributori.map(d => d.id));

  console.log(JSON.stringify({ event: 'fetch_prezzi_start' }));
  const prezziCsv   = await fetchCsv(MIMIT_PREZZI_URL);
  const tuttiPrezzi = await parsePrezzi(prezziCsv);
  const prezzi      = tuttiPrezzi.filter(p => idValidi.has(p.id_impianto));
  console.log(JSON.stringify({
    event:     'fetch_prezzi_done',
    count:     prezzi.length,
    scartati:  tuttiPrezzi.length - prezzi.length,
  }));

  let p_ins = 0;
  if (!DRY_RUN) {
    const { inserted, errors: p_err } = await batchUpsert('prezzi_correnti', prezzi, 1000);
    p_ins = inserted;
    console.log(JSON.stringify({ event: 'upsert_prezzi', inserted, errors: p_err }));

    // Elimina prezzi di stazioni non più nel CSV (chiuse, non comunicanti, ecc.).
    // Sicuro solo se abbiamo importato abbastanza righe (soglia 50.000).
    const { deleted, skipped, error: cleanErr } = await cleanupPrezziStale(runStartedAt, p_ins);
    console.log(JSON.stringify({
      event:   'cleanup_prezzi_stale',
      deleted,
      skipped,
      ...(cleanErr && { error: cleanErr }),
    }));
  }

  const ms = Date.now() - startedAt;
  console.log(JSON.stringify({
    event:        'import_done',
    ms,
    distributori: distributori.length,
    prezzi:       prezzi.length,
  }));
}

run().catch((err) => {
  console.error(JSON.stringify({ event: 'import_error', message: err.message }));
  process.exit(1);
});
