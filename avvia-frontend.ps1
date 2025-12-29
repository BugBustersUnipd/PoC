# Script PowerShell per avviare il frontend Angular
# Utilizzo: .\avvia-frontend.ps1

Write-Host "Avvio Frontend Angular..." -ForegroundColor Green

# Vai nella cartella frontend
Set-Location frontend

# Verifica che le dipendenze siano installate
if (-not (Test-Path "node_modules")) {
    Write-Host "Installazione dipendenze Node.js..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Errore durante l'installazione delle dipendenze!" -ForegroundColor Red
        Set-Location ..
        exit 1
    }
}

# Avvia il server di sviluppo
Write-Host "Avvio server Angular su http://localhost:4200" -ForegroundColor Green
npm start

# Torna alla directory principale quando il server si ferma
Set-Location ..
