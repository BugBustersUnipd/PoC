# 🚀 Guida per Testare il POC Nexum

Questa guida ti spiega passo-passo come avviare e testare il POC.

## 📋 Prerequisiti

Prima di iniziare, assicurati di avere installato:

1. **Ruby 3.4.x** e Bundler
2. **PostgreSQL** (versione 14+) in esecuzione
3. **Node.js** (per il frontend Angular)
4. **Credenziali AWS** con accesso a Bedrock (Access Key, Secret Key, eventualmente Session Token)
5. **Git** (opzionale, se devi clonare il progetto)

## 🔧 Setup Backend (Rails)

### 1. Vai nella cartella backend
```powershell
cd backend
```

### 2. Installa le gem Ruby
```powershell
bundle install
```

### 3. Configura le variabili d'ambiente AWS

Crea un file `.env` nella cartella `backend` con le tue credenziali AWS:

```env
AWS_ACCESS_KEY_ID=la_tua_access_key
AWS_SECRET_ACCESS_KEY=la_tua_secret_key
AWS_SESSION_TOKEN=la_tua_session_token_se_presente
AWS_REGION=us-east-1
```

**Nota:** Il file `.env` dovrebbe essere ignorato da git per sicurezza.

### 4. Configura il database

Assicurati che PostgreSQL sia in esecuzione e che l'utente `postgres` abbia password `2909` (come configurato in `config/database.yml`), oppure modifica il file di configurazione.

Poi crea e inizializza il database:

```powershell
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

Il seed crea:
- Una Company (ID=1)
- Alcuni Tone di esempio
- Una conversazione di esempio

### 5. Avvia il server Rails

```powershell
bin/rails s
```

Il server sarà disponibile su **http://localhost:3000**

## 🎨 Setup Frontend (Angular)

Apri un **nuovo terminale** e:

### 1. Vai nella cartella frontend
```powershell
cd frontend
```

### 2. Installa le dipendenze Node.js
```powershell
npm install
```

### 3. Avvia il server di sviluppo Angular
```powershell
npm start
```

Oppure:
```powershell
ng serve
```

Il frontend sarà disponibile su **http://localhost:4200**

## ✅ Come Testare il POC

### Test tramite Pagine HTML (più semplice)

Con il backend Rails in esecuzione (porta 3000), puoi utilizzare le pagine di test HTML:

1. **Test Generazione Testo con Conversazioni:**
   - Vai su: http://localhost:3000/tester.html
   - Carica i toni disponibili
   - Crea o seleziona una conversazione
   - Invia un prompt e verifica la risposta AI

2. **Test Analisi Documenti:**
   - Vai su: http://localhost:3000/documentTester.html
   - Carica un documento (PDF o immagine)
   - Attendi l'analisi (il sistema farà polling dello stato)
   - Visualizza i risultati

### Test tramite API (curl o Postman)

#### 1. Generare testo
```powershell
curl -X POST http://localhost:3000/genera `
  -H "Content-Type: application/json" `
  -d '{\"prompt\":\"Scrivi un email introduttiva\",\"tone\":\"Formale\",\"company_id\":1}'
```

#### 2. Ottenere i toni disponibili
```powershell
curl http://localhost:3000/toni?company_id=1
```

#### 3. Ottenere le conversazioni
```powershell
curl http://localhost:3000/conversazioni?company_id=1
```

#### 4. Caricare e analizzare un documento
```powershell
curl -X POST http://localhost:3000/documents `
  -F "document[original_file]=@C:\percorso\al\file.pdf"
```

#### 5. Verificare lo stato di un documento
```powershell
curl http://localhost:3000/documents/1
```

### Test tramite Frontend Angular

1. Avvia sia il backend (porta 3000) che il frontend (porta 4200)
2. Apri il browser su: http://localhost:4200
3. Naviga tra le varie pagine dell'applicazione Angular

## 🔍 Endpoint API Disponibili

- `POST /genera` - Genera testo usando AI
- `GET /toni?company_id=ID` - Ottieni lista toni per una company
- `GET /conversazioni?company_id=ID` - Ottieni lista conversazioni
- `POST /documents` - Carica un documento per l'analisi
- `GET /documents/:id` - Ottieni stato e risultati di un documento
- `GET /up` - Health check dell'applicazione

## ⚠️ Troubleshooting

### Il server Rails non si avvia
- Verifica che PostgreSQL sia in esecuzione
- Controlla che le migrazioni siano state eseguite (`bin/rails db:migrate`)
- Verifica che le variabili AWS siano configurate nel file `.env`

### Errore di connessione al database
- Controlla che PostgreSQL sia in esecuzione
- Verifica username/password in `config/database.yml`
- Assicurati che il database sia stato creato (`bin/rails db:create`)

### Errore AWS Bedrock (AccessDenied/Throttling)
- Verifica che le credenziali AWS siano corrette
- Controlla che il modello Bedrock sia abilitato nella regione configurata
- Verifica i permessi IAM per Bedrock

### Il frontend Angular non si avvia
- Assicurati che Node.js sia installato correttamente
- Esegui `npm install` nella cartella frontend
- Verifica che la porta 4200 non sia già in uso

## 📝 Note Importanti

- Il backend deve essere in esecuzione per far funzionare le pagine HTML di test
- Le variabili d'ambiente AWS sono necessarie per le funzionalità AI
- In sviluppo, il sistema usa code async per i job in background
- I file caricati vengono salvati localmente tramite Active Storage

## 🐳 Deploy con Docker (Opzionale)

Se preferisci usare Docker:

```powershell
docker build -t nexum_poc .
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<master_key> -e AWS_ACCESS_KEY_ID=... -e AWS_SECRET_ACCESS_KEY=... --name nexum_poc nexum_poc
```

---

**Buon test! 🎉**
