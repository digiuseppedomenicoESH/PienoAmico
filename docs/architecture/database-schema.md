# Database Schema — PienoAmico

## Diagramma ER

```
distributori                         prezzi_correnti
─────────────────────────────        ──────────────────────────────────
id            INTEGER  PK     ◄──── id_impianto    INTEGER  PK, FK
gestore       VARCHAR(200)          carburante      carburante_enum  PK
bandiera      VARCHAR(100)          is_self         BOOLEAN  PK
tipo_impianto tipo_impianto_enum    prezzo          NUMERIC(5,3)
nome          VARCHAR(200)          dt_comunicazione TIMESTAMPTZ
indirizzo     VARCHAR(300)          updated_at      TIMESTAMPTZ
comune        VARCHAR(100)
provincia     CHAR(2)
posizione     GEOGRAPHY(POINT,4326)  ← GIST index
attivo        BOOLEAN
updated_at    TIMESTAMPTZ
```

## Scelta GEOGRAPHY vs GEOMETRY

Si usa `GEOGRAPHY(POINT, 4326)` invece di `GEOMETRY` per due motivi:
1. `ST_DWithin` su GEOGRAPHY usa **metri** direttamente (nessuna conversione)
2. Calcola distanze su sferoide (più accurato su distanze > 1km)

Il trade-off è una leggera overhead computazionale rispetto a GEOMETRY — irrilevante per questa use case.

## Indici e Motivazione

### Tabella `distributori`

| Indice | Tipo | Colonne | Motivazione |
|--------|------|---------|-------------|
| `idx_distributori_posizione` | GIST | `posizione` | Cuore del sistema. Permette `ST_DWithin` in O(log n) invece di O(n) |
| `idx_distributori_provincia` | B-Tree | `provincia` | Future feature: ricerca per regione/provincia |
| `idx_distributori_autostradale` | B-Tree parziale | `tipo_impianto` WHERE autostradale | Il subset autostrade è piccolo (~5%); indice parziale = overhead minimo |

### Tabella `prezzi_correnti`

| Indice | Tipo | Colonne | Motivazione |
|--------|------|---------|-------------|
| `idx_prezzi_carburante_prezzo` | B-Tree | `(carburante, prezzo ASC)` | Ordinamento per prezzo in O(log n) |
| `idx_prezzi_dt_comunicazione` | B-Tree | `dt_comunicazione DESC` | Filtro `> now() - 48h` senza full scan |
| `idx_prezzi_self` | B-Tree parziale | `(carburante, prezzo)` WHERE `is_self=true` | Metà delle query è solo self-service: indice dedicato 2x più veloce |
| `idx_prezzi_servito` | B-Tree parziale | `(carburante, prezzo)` WHERE `is_self=false` | Stessa logica per servito |

## Perché nessuna tabella storica

La tabella `prezzi_correnti` ha come chiave primaria `(id_impianto, carburante, is_self)` e contiene **solo l'ultimo valore**. Ogni upsert sovrascrive il prezzo precedente.

Vantaggi:
- Dimensione stabile: ~60k-100k righe indipendentemente dal tempo
- Query veloci: nessun `GROUP BY MAX(data)` o subquery temporali
- Upsert idempotente: si può rieseguire lo script senza duplicati

Se in futuro si volesse lo storico, si aggiungerebbe una tabella `prezzi_storici` separata — senza toccare la struttura attuale.

## Volumi Stimati

| Tabella | Righe | Storage stimato |
|---------|-------|----------------|
| `distributori` | ~20.000 | ~8 MB |
| `prezzi_correnti` | ~80.000 | ~12 MB |
| **Totale** | | **~20 MB** (ben sotto i 500 MB del free tier) |
