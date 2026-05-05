// Parser del CSV prezzo_alle_8.csv
// Separatore: | (pipe) — cambiato dal 10/02/2026
// Formato dtComu: "GG/MM/AAAA HH:MM:SS" → convertire in ISO 8601

import { parse } from 'csv-parse';
import { Readable } from 'stream';

// Mapping da descCarburante MIMIT → carburante_enum Supabase
const CARBURANTE_MAP = {
  'Benzina':        'benzina',
  'Gasolio':        'gasolio',
  'Diesel':         'gasolio',
  'Blue Diesel':    'gasolio',
  'Gasolio Blue':   'gasolio',
  'GPL':            'gpl',
  'G.P.L.':         'gpl',
  'Metano':         'metano',
  'Metano L.':      'metano',
  'HVO':            'hvo',
};

/**
 * Converte "GG/MM/AAAA HH:MM:SS" in ISO 8601 UTC.
 * @param {string} dtComu
 * @returns {string|null}
 */
function parseDtComu(dtComu) {
  if (!dtComu) return null;
  // Formato atteso: "04/05/2026 08:15:32"
  const match = dtComu.match(/^(\d{2})\/(\d{2})\/(\d{4}) (\d{2}):(\d{2}):(\d{2})$/);
  if (!match) return null;
  const [, gg, mm, aaaa, hh, min, ss] = match;
  // I gestori comunicano in ora italiana — trattare come Europe/Rome
  // Per semplicità nella v1 usiamo il timestamp così com'è (differenza di 1-2h irrilevante)
  return `${aaaa}-${mm}-${gg}T${hh}:${min}:${ss}+01:00`;
}

/**
 * @param {string} csvText  - Contenuto raw del CSV
 * @returns {Promise<Array>} - Array di oggetti pronti per upsert su Supabase
 */
export async function parsePrezzi(csvText) {
  // Anche il CSV prezzi può iniziare con "Estrazione del AAAA-MM-GG" — skipparla se presente
  const lines = csvText.split('\n');
  const csvPulito = lines[0].startsWith('Estrazione') ? lines.slice(1).join('\n') : csvText;

  return new Promise((resolve, reject) => {
    const records = [];

    Readable.from([csvPulito])
      .pipe(parse({
        delimiter: '|',
        columns: true,
        skip_empty_lines: true,
        trim: true,
        quote: false,        // il CSV MIMIT non usa quote
        relax_column_count: true,
      }))
      .on('data', (row) => {
        const idImpianto = parseInt(row['idImpianto'], 10);
        const prezzo = parseFloat(row['prezzo']);

        // Salta righe con dati invalidi o prezzo zero
        if (isNaN(idImpianto) || isNaN(prezzo) || prezzo <= 0) return;

        const carburanteRaw = row['descCarburante']?.trim();
        const carburante = CARBURANTE_MAP[carburanteRaw] ?? 'altro';

        const dtComunicazione = parseDtComu(row['dtComu']);
        if (!dtComunicazione) return;

        records.push({
          id_impianto:      idImpianto,
          carburante,
          is_self:          row['isSelf'] === '1',
          prezzo,
          dt_comunicazione: dtComunicazione,
          updated_at:       new Date().toISOString(),
        });
      })
      .on('end', () => {
        // Il CSV MIMIT può contenere duplicati per (id_impianto, carburante, is_self).
        // Teniamo solo il prezzo con dt_comunicazione più recente per ogni combinazione.
        const deduped = new Map();
        for (const record of records) {
          const key = `${record.id_impianto}|${record.carburante}|${record.is_self}`;
          const existing = deduped.get(key);
          if (!existing || record.dt_comunicazione > existing.dt_comunicazione) {
            deduped.set(key, record);
          }
        }
        resolve(Array.from(deduped.values()));
      })
      .on('error', reject);
  });
}
