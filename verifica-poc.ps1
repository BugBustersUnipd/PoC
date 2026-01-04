# Script PowerShell per verificare che il POC sia configurato correttamente
# Utilizzo: .\verifica-poc.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verifica Configurazione POC Nexum" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errori = 0

# 1. Verifica Ruby
Write-Host "1. Verifica Ruby..." -ForegroundColor Yellow
try {
    $rubyVersion = ruby --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Ruby installato: $rubyVersion" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Ruby non trovato" -ForegroundColor Red
        $errori++
    }
} catch {
    Write-Host "   ✗ Ruby non trovato" -ForegroundColor Red
    $errori++
}

# 2. Verifica PostgreSQL
Write-Host "2. Verifica PostgreSQL..." -ForegroundColor Yellow
try {
    $pgTest = Test-NetConnection -ComputerName localhost -Port 5432 -WarningAction SilentlyContinue
    if ($pgTest.TcpTestSucceeded) {
        Write-Host "   ✓ PostgreSQL in esecuzione sulla porta 5432" -ForegroundColor Green
    } else {
        Write-Host "   ✗ PostgreSQL non raggiungibile sulla porta 5432" -ForegroundColor Red
        $errori++
    }
} catch {
    Write-Host "   ✗ Errore nel test di connessione PostgreSQL" -ForegroundColor Red
    $errori++
}

# 3. Verifica Node.js
Write-Host "3. Verifica Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
    $npmVersion = npm --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Node.js installato: $nodeVersion" -ForegroundColor Green
        Write-Host "   ✓ npm installato: $npmVersion" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Node.js non trovato" -ForegroundColor Red
        $errori++
    }
} catch {
    Write-Host "   ✗ Node.js non trovato" -ForegroundColor Red
    $errori++
}

# 4. Verifica file .env
Write-Host "4. Verifica file .env..." -ForegroundColor Yellow
if (Test-Path "backend\.env") {
    Write-Host "   ✓ File .env trovato" -ForegroundColor Green
    
    # Verifica variabili
    $envContent = Get-Content "backend\.env" -Raw
    if ($envContent -match "AWS_ACCESS_KEY_ID") {
        Write-Host "   ✓ AWS_ACCESS_KEY_ID presente" -ForegroundColor Green
    } else {
        Write-Host "   ✗ AWS_ACCESS_KEY_ID mancante" -ForegroundColor Red
        $errori++
    }
    
    if ($envContent -match "AWS_SECRET_ACCESS_KEY") {
        Write-Host "   ✓ AWS_SECRET_ACCESS_KEY presente" -ForegroundColor Green
    } else {
        Write-Host "   ✗ AWS_SECRET_ACCESS_KEY mancante" -ForegroundColor Red
        $errori++
    }
} else {
    Write-Host "   ✗ File .env non trovato in backend/" -ForegroundColor Red
    $errori++
}

# 5. Verifica dipendenze Ruby
Write-Host "5. Verifica dipendenze Ruby..." -ForegroundColor Yellow
Set-Location backend
try {
    bundle check 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Dipendenze Ruby installate" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ Dipendenze Ruby non installate (eseguire: bundle install)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠ Impossibile verificare dipendenze Ruby" -ForegroundColor Yellow
}
Set-Location ..

# 6. Verifica dipendenze Node.js
Write-Host "6. Verifica dipendenze Node.js..." -ForegroundColor Yellow
if (Test-Path "frontend\node_modules") {
    Write-Host "   ✓ Dipendenze Node.js installate" -ForegroundColor Green
} else {
    Write-Host "   ⚠ Dipendenze Node.js non installate (eseguire: cd frontend && cmd /c 'npm install')" -ForegroundColor Yellow
}

# 7. Verifica database
Write-Host "7. Verifica database..." -ForegroundColor Yellow
Set-Location backend
try {
    $dbStatus = bundle exec rails db:migrate:status 2>&1 | Select-String "up" | Measure-Object
    if ($dbStatus.Count -gt 0) {
        Write-Host "   ✓ Database inizializzato ($($dbStatus.Count) migrazioni eseguite)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ Database non inizializzato (eseguire: bundle exec rails db:create db:migrate db:seed)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠ Impossibile verificare stato database" -ForegroundColor Yellow
}
Set-Location ..

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($errori -eq 0) {
    Write-Host "  ✓ Verifica completata senza errori critici" -ForegroundColor Green
} else {
    Write-Host "  ✗ Trovati $errori errori critici" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Per testare il POC:" -ForegroundColor Yellow
Write-Host "  1. Avvia backend: .\avvia-backend.ps1" -ForegroundColor White
Write-Host "  2. Avvia frontend: .\avvia-frontend.ps1" -ForegroundColor White
Write-Host "  3. Oppure avvia tutto: .\avvia-poc.ps1" -ForegroundColor White
Write-Host ""

