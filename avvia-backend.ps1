# Script PowerShell per avviare il backend Rails
# Utilizzo: .\avvia-backend.ps1

Write-Host "Avvio Backend Rails..." -ForegroundColor Green

# Vai nella cartella backend
Set-Location backend

# Verifica che le dipendenze siano installate
Write-Host "Verifica dipendenze Ruby..." -ForegroundColor Yellow
bundle check 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installazione gem Ruby..." -ForegroundColor Yellow
    bundle install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Errore durante l'installazione delle gem!" -ForegroundColor Red
        Set-Location ..
        exit 1
    }
    Write-Host "Gem installate con successo!" -ForegroundColor Green
}

# Verifica il database
Write-Host "Verifica database..." -ForegroundColor Yellow
$dbCheck = bundle exec rails db:version 2>&1
$dbExists = $LASTEXITCODE -eq 0

# Verifica se ci sono migrazioni pendenti
$pendingMigrations = bundle exec rails db:migrate:status 2>&1 | Select-String "down"
$hasPendingMigrations = $pendingMigrations -ne $null

if (-not $dbExists -or $hasPendingMigrations) {
    if (-not $dbExists) {
        Write-Host "Database non inizializzato. Eseguo setup..." -ForegroundColor Yellow
        
        # Crea database
        Write-Host "Creazione database..." -ForegroundColor Cyan
        bundle exec rails db:create 2>&1 | Where-Object {
            $_ -notmatch "VIPS-WARNING" -and 
            $_ -notmatch "unable to load.*vips-.*\.dll"
        } | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Errore nella creazione del database. Verifica che PostgreSQL sia in esecuzione e che le credenziali in config/database.yml siano corrette." -ForegroundColor Red
            Set-Location ..
            exit 1
        }
    }
    
    # Esegui migrazioni (anche se il database esiste già, potrebbe esserci una migrazione pendente)
    Write-Host "Esecuzione migrazioni..." -ForegroundColor Cyan
    bundle exec rails db:migrate 2>&1 | Where-Object {
        $_ -notmatch "VIPS-WARNING" -and 
        $_ -notmatch "unable to load.*vips-.*\.dll"
    } | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Errore durante le migrazioni!" -ForegroundColor Red
        Set-Location ..
        exit 1
    }
    
    # Popola database solo se non esisteva prima
    if (-not $dbExists) {
        Write-Host "Popolazione database con dati iniziali..." -ForegroundColor Cyan
        bundle exec rails db:seed 2>&1 | Where-Object {
            $_ -notmatch "VIPS-WARNING" -and 
            $_ -notmatch "unable to load.*vips-.*\.dll"
        } | Out-Host
    }
    Write-Host "Database pronto!" -ForegroundColor Green
}

# Verifica file .env
if (-not (Test-Path ".env")) {
    Write-Host "File .env non trovato!" -ForegroundColor Yellow
    Write-Host "Crea un file .env con le tue credenziali AWS:" -ForegroundColor Yellow
    Write-Host "AWS_ACCESS_KEY_ID=..." -ForegroundColor Cyan
    Write-Host "AWS_SECRET_ACCESS_KEY=..." -ForegroundColor Cyan
    Write-Host "AWS_REGION=us-east-1" -ForegroundColor Cyan
    Write-Host ""
    $continue = Read-Host "Vuoi continuare comunque? (S/N)"
    if ($continue -ne "S" -and $continue -ne "s") {
        Set-Location ..
        exit 0
    }
}

# Avvia il server
# Nota: I warning VIPS all'avvio sono innocui (moduli opzionali non disponibili su Windows)
Write-Host "Avvio server Rails su http://localhost:3000" -ForegroundColor Green
bundle exec rails s

# Torna alla directory principale quando il server si ferma
Set-Location ..
