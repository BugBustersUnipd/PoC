# Script per verificare la connessione a PostgreSQL
# Utilizzo: .\verifica-postgres.ps1

Write-Host "Verifica connessione PostgreSQL..." -ForegroundColor Green
Write-Host ""

$psqlPath = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
if (-not (Test-Path $psqlPath)) {
    # Prova a trovare psql nel PATH
    $psqlPath = (Get-Command psql -ErrorAction SilentlyContinue).Source
    if (-not $psqlPath) {
        Write-Host "PostgreSQL non trovato! Verifica che sia installato." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Trovato psql in: $psqlPath" -ForegroundColor Cyan
Write-Host ""

# Chiedi la password
$securePassword = Read-Host "Inserisci la password per l'utente 'postgres'" -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))

Write-Host ""
Write-Host "Test connessione..." -ForegroundColor Yellow

$env:PGPASSWORD = $password
$result = & $psqlPath -U postgres -h 127.0.0.1 -p 5432 -c "SELECT version();" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Connessione riuscita! PostgreSQL funziona correttamente." -ForegroundColor Green
    Write-Host ""
    Write-Host "Aggiorna il file backend/config/database.yml con la password corretta." -ForegroundColor Yellow
    Write-Host "Oppure esegui questo comando per aggiornare la password:" -ForegroundColor Yellow
    Write-Host "  (usa la password che hai appena inserito)" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Connessione fallita!" -ForegroundColor Red
    Write-Host "Errore: $result" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possibili soluzioni:" -ForegroundColor Yellow
    Write-Host "1. Verifica che PostgreSQL sia in esecuzione" -ForegroundColor Cyan
    Write-Host "2. Verifica username e password corretti" -ForegroundColor Cyan
    Write-Host "3. Verifica che PostgreSQL accetti connessioni da 127.0.0.1" -ForegroundColor Cyan
}

$env:PGPASSWORD = $null
