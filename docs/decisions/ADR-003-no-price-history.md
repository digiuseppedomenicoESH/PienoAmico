# ADR-003 — Nessuna Tabella Storica Prezzi

**Status:** Accepted
**Data:** Maggio 2026

## Contesto

Il MIMIT pubblica prezzi aggiornati 2 volte al giorno. Si doveva scegliere se:
- **Opzione A:** Salvare solo l'ultimo prezzo per ogni (impianto, carburante, modalità)
- **Opzione B:** Tenere uno storico completo di ogni aggiornamento

## Decisione

**Opzione A:** tabella `prezzi_correnti` con PRIMARY KEY `(id_impianto, carburante, is_self)`. Ogni upsert sovrascrive il valore precedente. Nessuna tabella storica nella v1.

## Motivazione

**Performance:** con storico, trovare il prezzo attuale richiederebbe `GROUP BY id_impianto, carburante, is_self ORDER BY dt_comunicazione DESC` — impossibile ottimizzare senza finestre analitiche. Con Opzione A: un semplice lookup per chiave primaria.

**Dimensione DB:** con 80k righe x 2 update/giorno = 160k righe/giorno = ~58M righe/anno. Sul free tier (500MB) si esaurirebbe in settimane. Con Opzione A: dimensione costante ~80k righe.

**Complessità:** storico richiederebbe retention policy, cleanup job, query più complesse.

**Valore per l'utente v1:** la feature "andamento prezzi nel tempo" non è nel MVP. Si può aggiungere in v2 con una tabella separata `prezzi_storici` senza toccare la struttura attuale.

## Conseguenze

- Positivo: query principali in O(1) per lookup chiave primaria
- Positivo: storage stabile e prevedibile
- Positivo: upsert idempotente — si può rieseguire lo script senza duplicati
- Negativo: nessun storico disponibile per grafici trend (feature futura)
- Negativo: se lo script fallisce un'esecuzione, quel dato è perso per sempre
