# Supabase RPC — Documentazione Funzioni

## `get_nearby_fuel`

Trova distributori di carburante entro un raggio dalla posizione dell'utente, con prezzi correnti.

### Signature

```sql
get_nearby_fuel(
    p_lat         FLOAT,
    p_lon         FLOAT,
    p_raggio_m    INTEGER  DEFAULT 5000,
    p_carburante  TEXT     DEFAULT 'benzina',
    p_is_self     BOOLEAN  DEFAULT NULL,
    p_limit       INTEGER  DEFAULT 30
) RETURNS TABLE (...)
```

### Parametri

| Parametro | Tipo | Default | Valori validi |
|-----------|------|---------|--------------|
| `p_lat` | FLOAT | — | Latitudine WGS84 (es. `45.4642`) |
| `p_lon` | FLOAT | — | Longitudine WGS84 (es. `9.1900`) |
| `p_raggio_m` | INTEGER | `5000` | 1000–20000 (metri) |
| `p_carburante` | TEXT | `'benzina'` | `benzina` `gasolio` `gpl` `metano` `hvo` |
| `p_is_self` | BOOLEAN | `NULL` | `null`=entrambi, `true`=self, `false`=servito |
| `p_limit` | INTEGER | `30` | 1–100 |

### Response

Array di oggetti JSON:

```json
[
  {
    "id": 1001,
    "nome": "Eni Loreto",
    "bandiera": "Agip Eni",
    "indirizzo": "Viale Monza 1",
    "comune": "Milano",
    "tipo_impianto": "stradale",
    "latitudine": 45.482,
    "longitudine": 9.220,
    "distanza_m": 843,
    "prezzo_self": 1.659,
    "prezzo_servito": 1.759,
    "dt_aggiornamento": "2026-05-05T08:15:32+00:00"
  }
]
```

### Note sui campi

| Campo | Note |
|-------|------|
| `prezzo_self` | `null` se il distributore non ha la modalità self per questo carburante, o se il prezzo ha più di 48 ore |
| `prezzo_servito` | Stessa logica |
| `dt_aggiornamento` | Timestamp più recente tra self e servito. Usare `.asAgo` per mostrarlo all'utente |
| `distanza_m` | In metri. Usare `double.asDistanza` extension per formattarlo |

### Ordinamento

I risultati sono ordinati per:
1. **Prezzo minimo disponibile** ASC (self o servito, in base a `p_is_self`)
2. **Distanza** ASC come tiebreaker

### Chiamata dall'app Flutter

```dart
final response = await supabase.rpc('get_nearby_fuel', params: {
  'p_lat':        45.4642,
  'p_lon':        9.1900,
  'p_raggio_m':   5000,
  'p_carburante': 'benzina',
  'p_is_self':    null,
  'p_limit':      30,
});
```

### Test diretto SQL

```sql
-- Cerca benzina entro 5km da Milano centro
SELECT * FROM get_nearby_fuel(45.4642, 9.1900, 5000, 'benzina', null, 10);

-- Solo self-service gasolio entro 10km
SELECT * FROM get_nearby_fuel(45.4642, 9.1900, 10000, 'gasolio', true, 20);
```

### Performance

- Target: **< 300ms** sul free tier Supabase
- Il bottleneck è `ST_DWithin` — ottimizzato dall'indice GIST su `posizione`
- Il filtro `EXISTS` sui prezzi avviene **dopo** il filtro spaziale (efficiente)
- Con i dati MIMIT reali (~20k distributori) si attestano tipicamente 50-150ms
