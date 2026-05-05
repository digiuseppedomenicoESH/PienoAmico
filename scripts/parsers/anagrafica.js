// Parser del CSV anagrafica_impianti_attivi.csv
// Separatore: | (pipe) — cambiato dal 10/02/2026
// Encoding: UTF-8
// Riga 0: "Estrazione del AAAA-MM-GG" → skippare
// Riga 1: header colonne
// Righe 2+: dati

import { parse } from 'csv-parse';
import { Readable } from 'stream';

const TIPO_MAP = {
  'Stradale':    'stradale',
  'Autostrada':  'autostradale',
};

/**
 * @param {string} csvText  - Contenuto raw del CSV
 * @returns {Promise<Array>} - Array di oggetti pronti per upsert su Supabase
 */
export async function parseAnagrafica(csvText) {
  const lines = csvText.split('\n');

  // Salta la prima riga (data estrazione) e lavora dal secondo in poi
  const csvSenzaDataEstrazione = lines.slice(1).join('\n');

  return new Promise((resolve, reject) => {
    const records = [];

    Readable.from([csvSenzaDataEstrazione])
      .pipe(parse({
        delimiter: '|',
        columns: true,
        skip_empty_lines: true,
        trim: true,
        quote: false,        // il CSV MIMIT non usa quote, disabilitiamo per evitare falsi positivi
        relax_column_count: true, // ignora righe con numero colonne diverso (dati sporchi)
      }))
      .on('data', (row) => {
        const lat = parseFloat(row['Latitudine']);
        const lon = parseFloat(row['Longitudine']);

        // Salta coordinate mancanti o nulle
        if (!lat || !lon || lat === 0 || lon === 0) return;

        const id = parseInt(row['idImpianto'], 10);
        if (isNaN(id)) return;

        records.push({
          id,
          gestore:       row['Gestore']       || null,
          bandiera:      row['Bandiera']      || null,
          tipo_impianto: TIPO_MAP[row['Tipo Impianto']] ?? 'stradale',
          nome:          row['Nome Impianto'] || null,
          indirizzo:     row['Indirizzo']     || null,
          comune:        row['Comune']        || null,
          provincia:     row['Provincia']     || null,
          // PostGIS GEOGRAPHY point: formato WKT "POINT(lon lat)"
          posizione:     `POINT(${lon} ${lat})`,
          attivo:        true,
          updated_at:    new Date().toISOString(),
        });
      })
      .on('end', () => resolve(records))
      .on('error', reject);
  });
}
