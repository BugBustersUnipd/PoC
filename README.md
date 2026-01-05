# NEXUM Proof-of-Concept (POC)

Questo repository contiene il Proof-of-Concept (POC) per **NEXUM**, la piattaforma HR sviluppata da Eggon in collaborazione con UNIPD.

Il POC si concentra su due ambiti funzionali principali:

1. **AI Assistant Generativo** – Creazione automatizzata di contenuti per comunicazioni interne
2. **AI Co-Pilot per i Consulenti del Lavoro (CdL)** – Riconoscimento, split e dispaccio massivo di documenti (es. cedolini)

## Obiettivo del POC
- Validare moduli sperimentali basati su AI e data analytics integrabili nell’ecosistema NEXUM.
- Dimostrare flussi end-to-end per:
  - Generazione di comunicati aziendali (con tono/stile personalizzabile)
  - Caricamento → Riconoscimento → Split → Dispaccio di documenti massivi
- Raggiungere i criteri di accettazione definiti nel capitolato.

## Tecnologie utilizzate
- **Cloud:** AWS
- **Frontend:** Angular / Next.js
- **Backend:** Ruby on Rails
- **Database:** PostgreSQL

## Configurazione database locale
- Copia [backend/config/database.yml.example](backend/config/database.yml.example) in [backend/config/database.yml](backend/config/database.yml).
- Imposta le variabili d'ambiente richieste (es. `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME_DEVELOPMENT`, `DB_NAME_TEST`, `DB_NAME_PRODUCTION*`); se non impostate, verranno usati i default nel file.
- Riavvia il backend dopo eventuali modifiche alla configurazione.