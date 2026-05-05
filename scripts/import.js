// Entry point pipeline importazione dati MIMIT → Supabase.
// Eseguito da GitHub Actions due volte al giorno (08:30 e 14:30 ora italiana).

import 'dotenv/config';
import { batchUpsert } from './supabase_client.js';
import { parseAnagrafica } from './parsers/anagrafica.js';
import { parsePrezzi } from './parsers/prezzi.js';

const MIMIT_ANAGRAFICA_URL = 'https://www.mimit.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv';
const MIMIT_PREZZI_URL     = 'https://www.mimit.gov.it/images/exportCSV/prezzo_alle_8.csv';

const DRY_RUN = process.env.DRY_RUN === 'true';

async function fetchCsv(url) {
  const res = await fetch(url, {
    headers: { 'Accept-Encoding': 'gzip, deflate' },
    signal: AbortSignal.timeout(30_000), // timeout 30s
  });

  if (!res.ok) {
    throw new Error(`HTTP ${res.status} scaricando ${url}`);
  }

  return res.text();
}

async function run() {
  const startedAt = Date.now();
  console.log(JSON.stringify({ event: 'import_start', dry_run: DRY_RUN, ts: new Date().toISOString() }));

  // ── Step 1: Anagrafica ───────────────────────────────────────────────────
  console.log(JSON.stringify({ event: 'fetch_anagrafica_start' }));
  const anagraficaCsv = await fetchCsv(MIMIT_ANAGRAFICA_URL);
  const distributori  = await parseAnagrafica(anagraficaCsv);
  console.log(JSON.stringify({ event: 'fetch_anagrafica_done', count: distributori.length }));

  if (!DRY_RUN) {
    const { inserted: d_ins, errors: d_err } = await batchUpsert('distributori', distributori, 500);
    console.log(JSON.stringify({ event: 'upsert_distributori', inserted: d_ins, errors: d_err }));
  }

  // ── Step 2: Prezzi ───────────────────────────────────────────────────────
  // Costruiamo un Set degli ID distributori validi per filtrare prezzi orfani.
  // Il CSV prezzi può riferirsi a impianti non presenti nell'anagrafica (cessati, incoerenze MIMIT).
  const idValidi = new Set(distributori.map(d => d.id));

  console.log(JSON.stringify({ event: 'fetch_prezzi_start' }));
  const prezziCsv  = await fetchCsv(MIMIT_PREZZI_URL);
  const tuttiPrezzi = await parsePrezzi(prezziCsv);
  const prezzi      = tuttiPrezzi.filter(p => idValidi.has(p.id_impianto));
  console.log(JSON.stringify({
    event: 'fetch_prezzi_done',
    count: prezzi.length,
    scartati: tuttiPrezzi.length - prezzi.length,
  }));

  if (!DRY_RUN) {
    const { inserted: p_ins, errors: p_err } = await batchUpsert('prezzi_correnti', prezzi, 1000);
    console.log(JSON.stringify({ event: 'upsert_prezzi', inserted: p_ins, errors: p_err }));
  }

  const ms = Date.now() - startedAt;
  console.log(JSON.stringify({ event: 'import_done', ms, distributori: distributori.length, prezzi: prezzi.length }));
}

run().catch((err) => {
  console.error(JSON.stringify({ event: 'import_error', message: err.message }));
  process.exit(1);
});
