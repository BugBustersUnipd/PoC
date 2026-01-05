# Immagini e PDF di Test per OCR

Questa cartella contiene immagini e PDF di esempio per testare la funzionalità OCR dell'applicazione.

## Immagini disponibili

- **cedolino-test.png** / **cedolino-test.jpg** - Simula un cedolino stipendio con:
  - Dipendente: Mario Rossi
  - Codice Fiscale: RSSMRA80A01H501X
  - Data competenza: 31/12/2024

- **fattura-test.png** - Simula una fattura con:
  - Cliente: Azienda S.r.l.
  - Codice Fiscale: AZISRL80A01H501Y
  - Data emissione: 15/01/2024

- **cud-test.png** - Simula un CUD (Certificazione Unica) con:
  - Dipendente: Luigi Bianchi
  - Codice Fiscale: BNCLGU75B15H501Z
  - Anno: 2024

- **ricevuta-test.png** - Simula una ricevuta semplice

## Immagini con strutture diverse (per test variabilità OCR)

Queste immagini testano l'OCR con layout e campi diversi:

### Con Matricola e CF
- **cedolino-matricola-test.png** - Cedolino con MATRICOLA + CF (info in alto, layout aziendale)

### Solo Nome (senza CF)
- **fattura-solo-nome-test.png** - Fattura con SOLO NOME cliente (layout orizzontale, senza CF)
- **cud-solo-nome-test.png** - CUD con SOLO NOME dipendente (senza CF)

### Più Nomi (destinatario, mittente, dipendente)
- **documento-piu-nomi-test.png** - Documento con MITTENTE, DESTINATARIO e DIPENDENTE (3 nomi diversi)

### Layout Invertiti
- **cedolino-info-sotto-test.png** - Cedolino con INFO IN BASSO (layout invertito, dati dipendente in fondo)

### Layout a Tabella
- **fattura-tabella-test.png** - Fattura con layout a TABELLA (struttura complessa con colonne)

## PDF con strutture diverse

Versioni PDF delle strutture diverse:
- **cedolino-matricola-test.pdf** - Con matricola e CF
- **fattura-solo-nome-test.pdf** - Solo nome (senza CF)
- **documento-piu-nomi-test.pdf** - Più nomi (mittente, destinatario, dipendente)
- **cedolino-info-sotto-test.pdf** - Info in basso (layout invertito)
- **cud-solo-nome-test.pdf** - Solo nome (senza CF)

## Immagini sfocate (per test robustezza OCR)

Queste immagini testano la capacità dell'OCR di funzionare anche con immagini di qualità inferiore:

- **cedolino-test-sfocato-leggero.png** - Versione leggermente sfocata (ancora facilmente leggibile)
- **fattura-test-sfocato-leggero.png** - Versione leggermente sfocata
- **cud-test-sfocato-leggero.png** - Versione leggermente sfocata
- **cedolino-test-sfocato-moderato.png** - Versione moderatamente sfocata (più difficile da leggere)
- **fattura-test-sfocato-moderato.png** - Versione moderatamente sfocata
- **cedolino-test-sfocato-forte.png** - Versione molto sfocata (test estremo)

## PDF disponibili

- **cedolino-test.pdf** - PDF che simula un cedolino stipendio con:
  - Dipendente: Mario Rossi
  - Codice Fiscale: RSSMRA80A01H501X
  - Data competenza: 31/12/2024

- **fattura-test.pdf** - PDF che simula una fattura con:
  - Cliente: Azienda S.r.l.
  - Codice Fiscale: AZISRL80A01H501Y
  - Data emissione: 15/01/2024

- **cud-test.pdf** - PDF che simula un CUD (Certificazione Unica) con:
  - Dipendente: Luigi Bianchi
  - Codice Fiscale: BNCLGU75B15H501Z
  - Anno: 2024

- **ricevuta-test.pdf** - PDF che simula una ricevuta semplice

- **busta-paga-test.pdf** - PDF che simula una busta paga dettagliata con:
  - Dipendente: Anna Verdi
  - Codice Fiscale: VRDNNA85C45H501W
  - Data competenza: 31/12/2024
  - Dettagli competenze e trattenute

## Come usare

1. Avvia il server Rails (se non è già in esecuzione):
   ```powershell
   .\avvia-backend.ps1
   ```

2. Apri il tester nel browser:
   ```
   http://localhost:3000/documentTester.html
   ```

3. Carica una delle immagini dalla cartella `immagini-test/`

4. L'AI analizzerà l'immagine ed estrarrà:
   - tipo_documento
   - data_competenza
   - codice_fiscale
   - dipendente

## Formati supportati

L'applicazione supporta:
- PNG
- JPEG/JPG
- WebP
- PDF

## Rigenerare i file

Se vuoi rigenerare le immagini e i PDF di test, esegui:
```powershell
python ..\genera-immagini-test.py
```

Lo script genererà sia le immagini (PNG, JPG) che i PDF nella stessa cartella.

