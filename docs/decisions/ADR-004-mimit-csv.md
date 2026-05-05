# ADR-004 — Sorgente Dati: CSV MIMIT vs API non ufficiale

**Status:** Accepted
**Data:** Maggio 2026

## Contesto

Esistono due modi per ottenere i dati prezzi carburante:
- **CSV ufficiali MIMIT:** file scaricabili pubblicamente, dati aggregati 2x/giorno
- **API REST non ufficiale** su `carburanti.mise.gov.it/ricerca/`: endpoint non documentati, nessun SLA, usati dal sito web del Ministero

## Decisione

**CSV MIMIT** come sorgente primaria. L'API non ufficiale non viene usata.

## Motivazione

| Criterio | CSV MIMIT | API non ufficiale |
|----------|-----------|------------------|
| Ufficialità | **Sì — Open Data** | No — reverse engineered |
| Stabilità URL | **Alta** (cambia raramente) | Bassa (può cambiare senza preavviso) |
| SLA / Uptime | Nessuno, ma storicamente stabile | Nessuno |
| Rate limiting | Nessuno (download file) | Possibile |
| Dati completi | **Sì — tutti gli impianti nazionali** | Parziali (paginati per area) |
| Formato | CSV con pipe `\|` | JSON |
| Autenticazione richiesta | No | No (per ora) |

L'API non ufficiale richiederebbe molte chiamate paginate per coprire l'Italia intera. I CSV danno tutto in due file. Più semplice, più robusto.

## Conseguenze

- Positivo: dati completi nazionali in due download
- Positivo: nessun rischio di ban o rate limiting
- Positivo: base legale chiara (Open Data governativo)
- Negativo: latenza dati di 30-90 minuti rispetto alla comunicazione dei gestori (accettabile per un'app consumer)
- Negativo: URL può cambiare con restyling del sito MIMIT (monitorare nel workflow)

## Monitoraggio URL

Il workflow GitHub Actions deve fallire esplicitamente con `HTTP 404` se l'URL cambia, triggering email di notifica automatica da GitHub.
