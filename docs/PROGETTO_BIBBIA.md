# PienoAmico — Documento di Progetto
**App Android per il Monitoraggio Prezzi Carburante in Italia**
> Versione 1.0 — Maggio 2026 | Documento di riferimento tecnico e di business

---

## Indice
1. [Visione e Obiettivo](#1-visione-e-obiettivo)
2. [Logica di Business](#2-logica-di-business)
3. [Sorgente Dati MIMIT — Analisi Tecnica](#3-sorgente-dati-mimit--analisi-tecnica)
4. [Architettura del Sistema](#4-architettura-del-sistema)
5. [Database Schema — Ottimizzato](#5-database-schema--ottimizzato)
6. [Pipeline di Importazione Dati](#6-pipeline-di-importazione-dati)
7. [API Layer (Supabase)](#7-api-layer-supabase)
8. [Applicazione Flutter](#8-applicazione-flutter)
9. [Strategia di Performance](#9-strategia-di-performance)
10. [Monetizzazione](#10-monetizzazione)
11. [Analisi dei Costi](#11-analisi-dei-costi)
12. [Roadmap di Sviluppo](#12-roadmap-di-sviluppo)
13. [Limiti e Rischi Noti](#13-limiti-e-rischi-noti)

---

## 1. Visione e Obiettivo

### 1.1 Problema da risolvere
L'utente automobilista italiano non ha un modo rapido, affidabile e gratuito per trovare il distributore di carburante più economico nelle vicinanze. Le soluzioni esistenti sono lente, piene di pubblicità invasiva o basate su dati non ufficiali/non aggiornati.

### 1.2 Soluzione
**PienoAmico** è un'app Android nativa che, sfruttando i dati ufficiali e gratuiti del Ministero delle Imprese e del Made in Italy (MIMIT), mostra in tempo reale i distributori nelle vicinanze ordinati per prezzo, con mappa e navigazione integrata.

### 1.3 Proposta di Valore
- Dati **ufficiali** e **aggiornati due volte al giorno**
- Interfaccia **ultraveloce** — risultati in < 500ms
- **Zero abbonamenti** per l'utente finale
- Funzionamento **anche offline** (cache locale)
- **Gratuita** con pubblicità non invasiva

### 1.4 Target Utente
Automobilista italiano, 25-60 anni, che percorre almeno 10.000 km/anno e vuole risparmiare sul carburante.

---

## 2. Logica di Business

### 2.1 Flusso Principale (Happy Path)
```
Apertura App
    → Richiesta permesso GPS (se non già concesso)
    → Acquisizione posizione utente
    → Query al DB: distributori entro N km ordinati per prezzo
    → Visualizzazione lista + mappa
    → Tap su distributore → Dettaglio prezzi (tutti i tipi + self/servito)
    → Tap "Naviga" → Apertura Google Maps / Waze con coordinate
```

### 2.2 Regole di Business

| Regola | Specifica |
|--------|-----------|
| **Raggio di ricerca default** | 5 km dalla posizione utente |
| **Raggio massimo selezionabile** | 20 km |
| **Aggiornamento dati** | Due volte al giorno: 08:00 e 14:00 (trigger GitHub Actions) |
| **Validità cache locale** | 4 ore dalla ricezione |
| **Distributori mostrati** | Solo quelli con almeno un prezzo comunicato nelle ultime 48 ore |
| **Ordinamento default** | Per prezzo crescente del carburante selezionato |
| **Prezzi visualizzati** | Self-service e Servito sempre separati e chiaramente distinti |
| **Tipi carburante supportati** | Benzina, Gasolio, GPL, Metano, HVO |

### 2.3 Stati dell'App

```
LOADING      → posizione in acquisizione o query in corso
RESULTS      → lista distributori disponibile
EMPTY        → nessun distributore nel raggio selezionato
OFFLINE      → nessuna connessione, mostra cache locale (se disponibile)
ERROR        → errore generico (con possibilità di retry)
NO_GPS       → permesso GPS negato (con prompt per abilitarlo)
STALE_DATA   → cache scaduta + nessuna connessione
```

### 2.4 Filtri disponibili per l'utente
- Tipo carburante (Benzina / Gasolio / GPL / Metano / HVO)
- Modalità erogazione (Self / Servito / Entrambi)
- Raggio (5 / 10 / 20 km — slider)
- Ordinamento (Prezzo / Distanza)
- Tipo impianto (Stradale / Autostradale)

---

## 3. Sorgente Dati MIMIT — Analisi Tecnica

### 3.1 File CSV Ufficiali

Il MIMIT espone due file CSV pubblici, aggiornati quotidianamente, sul portale **Osservaprezzi Carburanti**.

> **IMPORTANTE — Cambio formato del 10/02/2026:** il separatore è passato dalla virgola `,` al pipe `|`. Tutti gli script devono usare `|` come delimiter.

---

#### File 1 — Anagrafica Impianti Attivi

**URL:** `https://www.mimit.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv`

**Encoding:** UTF-8 | **Separatore:** `|` | **Header:** riga 1 (dopo la prima riga di data estrazione)

**Struttura:**
| Colonna | Tipo | Note |
|---------|------|------|
| `idImpianto` | INTEGER | Chiave primaria MIMIT |
| `Gestore` | VARCHAR | Nome operatore/gestore |
| `Bandiera` | VARCHAR | Brand (Eni, Q8, IP, ecc.) |
| `Tipo Impianto` | VARCHAR | `Stradale` o `Autostrada` |
| `Nome Impianto` | VARCHAR | Denominazione impianto |
| `Indirizzo` | VARCHAR | Via/strada |
| `Comune` | VARCHAR | Nome comune |
| `Provincia` | CHAR(2) | Sigla provincia (es. `MI`) |
| `Latitudine` | DECIMAL | WGS84 |
| `Longitudine` | DECIMAL | WGS84 |

**Esempio di dati reali:**
```
Estrazione del 2026-05-04
idImpianto|Gestore|Bandiera|Tipo Impianto|Nome Impianto|Indirizzo|Comune|Provincia|Latitudine|Longitudine
59183|ENIMOOV S.P.A.|Agip Eni|Stradale|19829 AGRIGENTO|SS.189 KM. 64+649|AGRIGENTO|AG|37.3086|13.5833
23778|ALFONSO DI BENEDETTO CARBURANTI|Sicilpetroli|Stradale|A. Di Benedetto srl|VIA PETRARCA|ALESSANDRIA|AL|44.9133|8.6333
```

**Dimensione stimata:** ~1.5 MB (circa 18.000-22.000 righe)

---

#### File 2 — Prezzi alle 8

**URL:** `https://www.mimit.gov.it/images/exportCSV/prezzo_alle_8.csv`

**Encoding:** UTF-8 | **Separatore:** `|` | **Header:** riga 1

**Struttura:**
| Colonna | Tipo | Note |
|---------|------|------|
| `idImpianto` | INTEGER | FK → anagrafica |
| `descCarburante` | VARCHAR | `Benzina`, `Gasolio`, `GPL`, `Metano`, `HVO`, ... |
| `prezzo` | DECIMAL(5,3) | Prezzo in euro, es. `1.685` |
| `isSelf` | TINYINT | `0` = Servito, `1` = Self-service |
| `dtComu` | CHAR(19) | Formato `GG/MM/AAAA HH:MM:SS` |

**Esempio di dati reali:**
```
idImpianto|descCarburante|prezzo|isSelf|dtComu
59183|Benzina|1.685|0|04/05/2026 08:15:32
59183|Gasolio|1.599|0|04/05/2026 08:15:32
59183|GPL|0.849|1|03/05/2026 14:22:10
23778|Benzina|1.702|1|02/05/2026 16:45:00
```

**Dimensione stimata:** ~3-5 MB (ogni impianto può avere 2-10 righe: tipi × modalità)

### 3.2 Frequenza aggiornamento MIMIT
Il MIMIT aggiorna i dati **due volte al giorno**. I gestori dei distributori comunicano i prezzi in modo asincrono, quindi `dtComu` varia da qualche ora a qualche giorno fa. La regola è: un prezzo è considerato **valido** se `dtComu` è entro le ultime 48 ore.

### 3.3 API REST non ufficiale (backup)
Esiste un'API REST non documentata ufficialmente:

```
Base URL: https://carburanti.mise.gov.it/ricerca/
Endpoint chiave: /position (POST)
Parametri: lat, lng, carb, ordPrice
```

**Strategia:** Non usarla come sorgente primaria (instabile, senza SLA). Usarla solo come fallback in caso di indisponibilità dei CSV.

---

## 4. Architettura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                      GITHUB ACTIONS                         │
│  Cron: 07:30 UTC e 13:30 UTC (8:30 e 14:30 italiane)       │
│                                                             │
│  1. Download anagrafica_impianti_attivi.csv (MIMIT)         │
│  2. Download prezzo_alle_8.csv (MIMIT)                      │
│  3. Parse + validate + transform (Node.js script)           │
│  4. Batch upsert → Supabase (REST API)                      │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS / REST
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   SUPABASE (Free Tier)                      │
│                                                             │
│  PostgreSQL 15 + PostGIS                                    │
│  ├── tabella: distributori  (anagrafica + geometria)        │
│  ├── tabella: prezzi_correnti  (ultimi prezzi)              │
│  ├── view: v_distributori_con_prezzi                        │
│  └── function: get_nearby_fuel(lat, lon, raggio, carb)      │
│                                                             │
│  Row Level Security: read-only pubblico                     │
│  Realtime: disabilitato (non necessario)                    │
└────────────────────────┬────────────────────────────────────┘
                         │ Supabase SDK
                         ▼
┌─────────────────────────────────────────────────────────────┐
│               APP FLUTTER (Android)                         │
│                                                             │
│  ├── Geolocalizzazione (geolocator)                         │
│  ├── Cache locale (Hive)  — TTL 4 ore                       │
│  ├── Mappa (flutter_map + OpenStreetMap tiles)              │
│  ├── Lista distributori (virtualizzata)                     │
│  └── Google AdMob (banner + interstitial)                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Database Schema — Ottimizzato

### 5.1 Estensioni richieste su Supabase
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm; -- per ricerca testuale futura
```

### 5.2 Tabella `distributori`
```sql
CREATE TABLE distributori (
    id              INTEGER PRIMARY KEY,          -- idImpianto MIMIT
    gestore         VARCHAR(200),
    bandiera        VARCHAR(100),
    tipo_impianto   tipo_impianto_enum NOT NULL DEFAULT 'stradale',
    nome            VARCHAR(200),
    indirizzo       VARCHAR(300),
    comune          VARCHAR(100),
    provincia       CHAR(2),
    posizione       GEOGRAPHY(POINT, 4326) NOT NULL,
    attivo          BOOLEAN NOT NULL DEFAULT true,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ENUM per tipo impianto (evita VARCHAR a runtime)
CREATE TYPE tipo_impianto_enum AS ENUM ('stradale', 'autostradale');

-- INDICE SPAZIALE — cuore delle query geografiche
CREATE INDEX idx_distributori_posizione
    ON distributori USING GIST (posizione);

-- Indice per filtrare per provincia (utile per future feature)
CREATE INDEX idx_distributori_provincia
    ON distributori (provincia);

-- Indice per filtro tipo impianto
CREATE INDEX idx_distributori_tipo
    ON distributori (tipo_impianto) WHERE tipo_impianto = 'autostradale';
```

### 5.3 Tabella `prezzi_correnti`
> Questa tabella contiene **SOLO l'ultimo prezzo comunicato** per ogni combinazione (impianto, carburante, modalità). Non è uno storico. Questo la mantiene piccola e le query veloci.

```sql
CREATE TYPE carburante_enum AS ENUM (
    'benzina', 'gasolio', 'gpl', 'metano', 'hvo', 'altro'
);

CREATE TABLE prezzi_correnti (
    id_impianto     INTEGER NOT NULL REFERENCES distributori(id) ON DELETE CASCADE,
    carburante      carburante_enum NOT NULL,
    is_self         BOOLEAN NOT NULL,
    prezzo          NUMERIC(5,3) NOT NULL,
    dt_comunicazione TIMESTAMPTZ NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    PRIMARY KEY (id_impianto, carburante, is_self)
);

-- Indice per filtrare per carburante + prezzo (la query più usata)
CREATE INDEX idx_prezzi_carburante_prezzo
    ON prezzi_correnti (carburante, prezzo ASC);

-- Indice per filtrare prezzi recenti (esclude dati stale)
CREATE INDEX idx_prezzi_dt_comunicazione
    ON prezzi_correnti (dt_comunicazione DESC);

-- Indice parziale per self-service (query frequente)
CREATE INDEX idx_prezzi_self
    ON prezzi_correnti (carburante, prezzo ASC) WHERE is_self = true;

-- Indice parziale per servito
CREATE INDEX idx_prezzi_servito
    ON prezzi_correnti (carburante, prezzo ASC) WHERE is_self = false;
```

### 5.4 Funzione PostGIS — Query Principale
```sql
-- Funzione ottimizzata: trova distributori vicini con prezzi
-- Parametri:
--   p_lat, p_lon  : coordinate utente
--   p_raggio_m    : raggio in metri (default 5000)
--   p_carburante  : tipo carburante ('benzina','gasolio',ecc.)
--   p_is_self     : NULL = entrambi, TRUE = solo self, FALSE = solo servito
--   p_limit       : numero massimo risultati (default 30)

CREATE OR REPLACE FUNCTION get_nearby_fuel(
    p_lat         FLOAT,
    p_lon         FLOAT,
    p_raggio_m    INTEGER  DEFAULT 5000,
    p_carburante  TEXT     DEFAULT 'benzina',
    p_is_self     BOOLEAN  DEFAULT NULL,
    p_limit       INTEGER  DEFAULT 30
)
RETURNS TABLE (
    id            INTEGER,
    nome          VARCHAR,
    bandiera      VARCHAR,
    indirizzo     VARCHAR,
    comune        VARCHAR,
    tipo_impianto tipo_impianto_enum,
    latitudine    FLOAT,
    longitudine   FLOAT,
    distanza_m    INTEGER,
    prezzo_self   NUMERIC,
    prezzo_servito NUMERIC,
    dt_aggiornamento TIMESTAMPTZ
)
LANGUAGE sql
STABLE
PARALLEL SAFE
AS $$
    SELECT
        d.id,
        d.nome,
        d.bandiera,
        d.indirizzo,
        d.comune,
        d.tipo_impianto,
        ST_Y(d.posizione::geometry)::FLOAT    AS latitudine,
        ST_X(d.posizione::geometry)::FLOAT    AS longitudine,
        ST_Distance(d.posizione, ST_MakePoint(p_lon, p_lat)::GEOGRAPHY)::INTEGER AS distanza_m,

        -- Prezzo self (NULL se non disponibile)
        (SELECT p.prezzo FROM prezzi_correnti p
         WHERE p.id_impianto = d.id
           AND p.carburante  = p_carburante::carburante_enum
           AND p.is_self     = true
           AND p.dt_comunicazione > now() - INTERVAL '48 hours'
         LIMIT 1) AS prezzo_self,

        -- Prezzo servito (NULL se non disponibile)
        (SELECT p.prezzo FROM prezzi_correnti p
         WHERE p.id_impianto = d.id
           AND p.carburante  = p_carburante::carburante_enum
           AND p.is_self     = false
           AND p.dt_comunicazione > now() - INTERVAL '48 hours'
         LIMIT 1) AS prezzo_servito,

        -- Data dell'aggiornamento più recente tra i prezzi
        (SELECT MAX(p.dt_comunicazione) FROM prezzi_correnti p
         WHERE p.id_impianto = d.id
           AND p.carburante  = p_carburante::carburante_enum
           AND p.dt_comunicazione > now() - INTERVAL '48 hours'
        ) AS dt_aggiornamento

    FROM distributori d
    WHERE
        d.attivo = true
        AND ST_DWithin(d.posizione, ST_MakePoint(p_lon, p_lat)::GEOGRAPHY, p_raggio_m)
        -- Includi solo impianti che hanno ALMENO un prezzo recente per questo carburante
        AND EXISTS (
            SELECT 1 FROM prezzi_correnti p
            WHERE p.id_impianto = d.id
              AND p.carburante  = p_carburante::carburante_enum
              AND p.dt_comunicazione > now() - INTERVAL '48 hours'
              AND (p_is_self IS NULL OR p.is_self = p_is_self)
        )

    ORDER BY
        -- Ordina per prezzo minimo disponibile, poi per distanza
        LEAST(
            COALESCE(
                (SELECT p.prezzo FROM prezzi_correnti p
                 WHERE p.id_impianto = d.id AND p.carburante = p_carburante::carburante_enum
                 AND (p_is_self IS NULL OR p.is_self = p_is_self)
                 AND p.dt_comunicazione > now() - INTERVAL '48 hours'
                 ORDER BY p.prezzo ASC LIMIT 1),
                9999
            )
        ) ASC,
        distanza_m ASC

    LIMIT p_limit;
$$;
```

### 5.5 Policy Row Level Security (RLS)
```sql
-- Abilita RLS su entrambe le tabelle
ALTER TABLE distributori      ENABLE ROW LEVEL SECURITY;
ALTER TABLE prezzi_correnti   ENABLE ROW LEVEL SECURITY;

-- Solo lettura pubblica (anonima) — nessuna scrittura dall'app
CREATE POLICY "read_only_public" ON distributori
    FOR SELECT TO anon USING (true);

CREATE POLICY "read_only_public" ON prezzi_correnti
    FOR SELECT TO anon USING (true);

-- La scrittura avviene SOLO tramite service_role (GitHub Actions)
```

---

## 6. Pipeline di Importazione Dati

### 6.1 GitHub Actions Workflow
**File:** `.github/workflows/update-prezzi.yml`

```yaml
name: Aggiornamento Prezzi Carburante

on:
  schedule:
    - cron: '30 6 * * *'   # 07:30 UTC = 08:30 ora italiana (CET+1)
    - cron: '30 12 * * *'  # 13:30 UTC = 14:30 ora italiana
  workflow_dispatch:        # esecuzione manuale per debug

jobs:
  update:
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: scripts/package-lock.json

      - name: Install dependencies
        run: cd scripts && npm ci

      - name: Run import script
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_SERVICE_KEY: ${{ secrets.SUPABASE_SERVICE_KEY }}
        run: cd scripts && node import.js
```

### 6.2 Script Node.js — Logica di Import
**File:** `scripts/import.js`

La logica segue questo flusso:

```
1. Download anagrafica CSV (stream, non buffer in memoria)
2. Parse anagrafica → Array<Distributore>
3. Batch upsert distributori in chunk da 500 righe
4. Download prezzi CSV (stream)
5. Parse prezzi → Array<Prezzo>
   - Filtra righe con prezzo = 0 o NULL
   - Normalizza descCarburante → carburante_enum
   - Converti dtComu "GG/MM/AAAA HH:MM:SS" → ISO 8601
6. Batch upsert prezzi in chunk da 1000 righe
7. Log statistiche: N distributori, M prezzi aggiornati, tempo esecuzione
```

**Mapping carburante_enum:**
```javascript
const CARBURANTE_MAP = {
  'Benzina':      'benzina',
  'Gasolio':      'gasolio',
  'GPL':          'gpl',
  'G.P.L.':       'gpl',
  'Metano':       'metano',
  'Metano L.':    'metano',
  'HVO':          'hvo',
  'Blue Diesel':  'gasolio',  // variante del gasolio
};
// Qualsiasi valore non mappato → 'altro'
```

**Chunk size ottimale per Supabase free tier:**
- Anagrafica: chunk da **500 righe** (payload ~150KB)
- Prezzi: chunk da **1000 righe** (payload ~80KB)

---

## 7. API Layer (Supabase)

### 7.1 Chiamata principale dall'app Flutter
```
POST /rest/v1/rpc/get_nearby_fuel
Authorization: Bearer <ANON_KEY>
Content-Type: application/json

{
  "p_lat": 45.4642,
  "p_lon": 9.1900,
  "p_raggio_m": 5000,
  "p_carburante": "benzina",
  "p_is_self": null,
  "p_limit": 30
}
```

**Response attesa (array JSON):**
```json
[
  {
    "id": 59183,
    "nome": "Agip Viale Monza",
    "bandiera": "Agip Eni",
    "indirizzo": "Viale Monza 120",
    "comune": "Milano",
    "tipo_impianto": "stradale",
    "latitudine": 45.4800,
    "longitudine": 9.2100,
    "distanza_m": 843,
    "prezzo_self": 1.659,
    "prezzo_servito": 1.759,
    "dt_aggiornamento": "2026-05-05T08:15:32+00:00"
  }
]
```

### 7.2 Headers obbligatori
```
apikey: <SUPABASE_ANON_KEY>
Authorization: Bearer <SUPABASE_ANON_KEY>
```

---

## 8. Applicazione Flutter

### 8.1 Struttura del Progetto
```
lib/
├── main.dart
├── app.dart                    # MaterialApp + tema
│
├── core/
│   ├── constants.dart          # URL Supabase, chiavi, costanti UI
│   ├── theme.dart              # Colori, font, stili
│   └── exceptions.dart         # Tipi di errore custom
│
├── data/
│   ├── supabase_service.dart   # Wrapper per chiamate Supabase
│   ├── location_service.dart   # GPS e permessi
│   └── cache_service.dart      # Hive — persistenza locale
│
├── models/
│   ├── distributore.dart       # Model + fromJson
│   └── filtri.dart             # Stato filtri utente
│
├── screens/
│   ├── home/
│   │   ├── home_screen.dart    # Schermata principale
│   │   ├── lista_widget.dart   # Lista distributori virtualizzata
│   │   └── mappa_widget.dart   # flutter_map
│   └── dettaglio/
│       └── dettaglio_screen.dart # Prezzi completi + naviga
│
└── widgets/
    ├── filtri_bottom_sheet.dart
    ├── distributore_card.dart
    └── prezzo_badge.dart
```

### 8.2 Dipendenze Flutter (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter

  # Backend
  supabase_flutter: ^2.x

  # Mappe
  flutter_map: ^7.x
  latlong2: ^0.9.x

  # Geolocalizzazione
  geolocator: ^13.x

  # Cache locale
  hive_flutter: ^1.x
  hive: ^2.x

  # Navigazione
  go_router: ^14.x

  # Pubblicità
  google_mobile_ads: ^5.x

  # Utility
  intl: ^0.19.x          # formattazione prezzi e date
  url_launcher: ^6.x     # apertura Google Maps / Waze
```

### 8.3 Schermata Home — Logica
```dart
// Sequenza di caricamento al primo avvio
1. Controllo cache Hive → se valida (< 4 ore) mostra subito i dati cached
2. In background (o se cache scaduta): richiedi posizione GPS
3. Chiamata Supabase RPC get_nearby_fuel
4. Aggiorna UI + salva in cache
```

### 8.4 Cache Strategy (Hive)
```dart
// Struttura dati in cache
{
  "key": "results_lat45.46_lon9.19_r5000_benzina",
  "data": [ ...lista distributori... ],
  "cached_at": "2026-05-05T08:30:00Z"
}

// TTL: 4 ore. Se scaduta → fetch da Supabase.
// Se fetch fallisce e cache esiste (anche scaduta) → mostra con banner "Dati non aggiornati"
```

---

## 9. Strategia di Performance

### 9.1 Database (Obiettivo: query < 300ms)

| Tecnica | Motivazione |
|---------|-------------|
| Indice GIST su `posizione` | Filtra geograficamente con B-Tree spaziale, O(log n) |
| ENUM types per carburante e tipo | Confronto intero vs string, storage ridotto |
| Indici parziali su `is_self` | Query 2x più veloci quando si filtra per modalità |
| Nessuna tabella storica prezzi | `prezzi_correnti` ha solo l'ultima riga per combinazione — rimane piccola |
| Subquery `EXISTS` nell'WHERE | Esclude impianti senza prezzi PRIMA del calcolo distanza |
| `STABLE` + `PARALLEL SAFE` sulla funzione | PostgreSQL può parallelizzare e mettere in cache il piano |
| `LIMIT` integrato nella funzione | Non porta mai più di 30 righe sul wire |

### 9.2 App Flutter (Obiettivo: first render < 500ms)

| Tecnica | Motivazione |
|---------|-------------|
| Cache locale Hive (TTL 4h) | Schermata istantanea al riavvio |
| Lista virtualizzata (`ListView.builder`) | Non renderizza tutti i card fuori schermo |
| Lazy loading mappe | I marker vengono caricati solo quando la mappa è visibile |
| Debounce su cambio filtri (300ms) | Evita query ridondanti durante lo swipe dello slider raggio |
| Compressione JSON Supabase (`Accept-Encoding: gzip`) | Riduce banda del 70-80% |
| Singleton `SupabaseClient` | Un'unica connessione HTTP riutilizzata per tutte le richieste |

### 9.3 Pipeline (Obiettivo: import < 5 minuti)

| Tecnica | Motivazione |
|---------|-------------|
| Stream CSV (no buffer completo) | RAM costante ~50MB indipendentemente dalla dimensione file |
| Batch upsert in chunk | Una sola request HTTP per 500-1000 righe invece di N |
| `ON CONFLICT DO UPDATE` (upsert) | Nessun DELETE + INSERT: aggiornamento chirurgico |
| Timeout Actions: 15 minuti | Safety net se MIMIT è lento |

---

## 10. Monetizzazione

### 10.1 Google AdMob — Configurazione

| Formato | Posizione | Frequenza | Note |
|---------|-----------|-----------|------|
| **Banner adattivo** | Fondo della lista | Sempre visibile | 320x50 o adattivo |
| **Interstitial** | Tap su "Avvia Navigazione" | Max 1 ogni 4 tap | Caricato in background |

### 10.2 Regole anti-spam pubblicità
- L'interstitial NON appare se l'utente ha già visto un interstitial negli ultimi 10 minuti
- Il banner NON appare nella schermata di caricamento GPS
- Nessun rewarded video nella v1.0 (complessità non giustificata)

### 10.3 Stima entrate (scenario conservativo)
- 1.000 utenti attivi/mese → ~30.000 sessioni
- eCPM Italia banner: ~€0.50 / 1000 visualizzazioni
- eCPM Italia interstitial: ~€3.00 / 1000 visualizzazioni
- Stima mensile v1: **€15-40/mese** (scala con gli utenti)

---

## 11. Analisi dei Costi

| Voce | Costo | Note |
|------|-------|------|
| Google Play Console | **€25,00** una tantum | Obbligatorio per pubblicazione |
| Supabase Free Tier | **€0,00/mese** | 500MB DB, 2GB bandwidth, PostGIS incluso |
| GitHub Actions | **€0,00/mese** | ~60 min/mese stimati (< 2000 min gratuiti) |
| OpenStreetMap tiles | **€0,00/mese** | Uso ragionevole per app non commerciale massiva |
| Google AdMob | **€0,00** | Nessun costo, solo ricavi |
| **TOTALE LANCIO** | **€25,00** | |
| **TOTALE MENSILE** | **€0,00** | |

### 11.1 Soglia di upgrade Supabase
Passare al piano Pro (€25/mese) solo se:
- Utenti attivi > 50.000/mese (bandwidth a rischio)
- DB supera 400MB (85% del free tier)
- Il progetto inizia a generare > €40/mese con AdMob

---

## 12. Roadmap di Sviluppo

### Fase 1 — Backend e Pipeline (Settimana 1)
- [ ] Creazione progetto Supabase + abilitazione PostGIS
- [ ] Esecuzione DDL: tabelle, indici, funzione PostGIS, RLS
- [ ] Script Node.js: download + parsing + upsert CSV MIMIT
- [ ] Test script in locale con dati reali
- [ ] Configurazione GitHub Actions + secrets
- [ ] Verifica prima esecuzione automatica
- [ ] Controllo qualità dati: conteggio distributori, prezzi presenti

### Fase 2 — App Flutter Core (Settimana 2)
- [ ] Setup progetto Flutter + dipendenze
- [ ] Integrazione Supabase SDK + chiamata RPC
- [ ] Schermata Home: lista distributori (solo lista, no mappa)
- [ ] Geolocalizzazione + permessi runtime Android
- [ ] Modello `Distributore` + deserializzazione JSON
- [ ] Filtri: carburante, raggio, self/servito
- [ ] Gestione stati: loading, empty, error, offline

### Fase 3 — Mappa e UX (Settimana 3)
- [ ] Integrazione `flutter_map` + tile OpenStreetMap
- [ ] Marker sulla mappa con prezzo inline
- [ ] Schermata Dettaglio (tutti i prezzi del distributore)
- [ ] Tasto "Naviga" (url_launcher → Google Maps)
- [ ] Cache locale Hive con TTL
- [ ] Banner "dati non aggiornati" per cache scaduta offline
- [ ] Integrazione Google AdMob (banner + interstitial)
- [ ] Schermata impostazioni: tipo carburante default

### Fase 4 — Release (Settimana 4)
- [ ] Test su almeno 2 dispositivi fisici Android (minSDK 23)
- [ ] Test scenario offline
- [ ] Test con GPS disabilitato
- [ ] Ottimizzazione performance (profiler Flutter)
- [ ] Icona app + splash screen
- [ ] Generazione keystore + firma .aab
- [ ] Privacy Policy (obbligatoria per AdMob) — pagina web statica
- [ ] Caricamento su Google Play Console
- [ ] Scheda Play Store: descrizione, screenshot, categorie

---

## 13. Limiti e Rischi Noti

| Rischio | Probabilità | Impatto | Mitigazione |
|---------|-------------|---------|-------------|
| URL CSV MIMIT cambia | Media | Alto | Script monitora HTTP status; alert via GitHub Actions se 404 |
| Supabase pausa progetto free | Bassa | Alto | GitHub Actions scrive ogni giorno → mai inattivo 7 giorni |
| Distributore non comunica prezzi | Alta (normale) | Basso | Filtro `dt_comunicazione > 48h` esclude dati stale |
| Rate limit OpenStreetMap tiles | Bassa | Medio | Cache tile lato flutter_map (built-in) |
| AdMob non approva l'account | Media | Basso | Processo di approvazione separato; app funziona senza ads |
| Dati MIMIT incompleti (coordinate mancanti) | Media | Basso | Script skips righe con lat/lon NULL o `0,0` |

---

## Appendice A — Variabili d'Ambiente

| Variabile | Dove | Scopo |
|-----------|------|-------|
| `SUPABASE_URL` | GitHub Secret + Flutter | Endpoint Supabase |
| `SUPABASE_SERVICE_KEY` | GitHub Secret ONLY | Scrittura DB (mai in app) |
| `SUPABASE_ANON_KEY` | Flutter (pubblica) | Lettura DB dall'app |
| `ADMOB_APP_ID` | AndroidManifest.xml | Identificativo AdMob |

> **IMPORTANTE:** La `SERVICE_KEY` non deve MAI finire nell'app. L'app usa solo la `ANON_KEY` (read-only per RLS).

---

## Appendice B — Struttura Repository

```
pienoamico/
├── .github/
│   └── workflows/
│       └── update-prezzi.yml
│
├── scripts/                    # Pipeline Node.js
│   ├── package.json
│   ├── import.js               # Entry point
│   ├── parsers/
│   │   ├── anagrafica.js
│   │   └── prezzi.js
│   └── supabase_client.js
│
├── supabase/
│   └── migrations/
│       ├── 001_schema.sql      # Tabelle + indici
│       ├── 002_functions.sql   # get_nearby_fuel
│       └── 003_rls.sql         # Row Level Security
│
├── app/                        # Progetto Flutter
│   ├── pubspec.yaml
│   └── lib/
│       └── ...
│
├── PROGETTO_BIBBIA.md          # Questo documento
└── README.md
```

---

*Documento aggiornato al 05/05/2026 — PienoAmico v1.0*
