# Script PowerShell per testare le funzionalità del POC
# Utilizzo: .\testa-poc.ps1
# Assicurati che il backend sia in esecuzione su http://localhost:3000

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Funzionali POC Nexum" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$BASE_URL = "http://localhost:3000"
$errori = 0
$testPassati = 0

# Funzione helper per testare endpoint
function Test-Endpoint {
    param(
        [string]$Method,
        [string]$Url,
        [string]$Description,
        [hashtable]$Body = $null,
        [hashtable]$Headers = @{"Content-Type" = "application/json"}
    )
    
    Write-Host "Test: $Description" -ForegroundColor Yellow
    Write-Host "  $Method $Url" -ForegroundColor Gray
    
    try {
        if ($Method -eq "GET") {
            $response = Invoke-WebRequest -Uri $Url -Method GET -ErrorAction Stop
        } else {
            $jsonBody = if ($Body) { $Body | ConvertTo-Json } else { "" }
            $response = Invoke-WebRequest -Uri $Url -Method $Method -Body $jsonBody -Headers $Headers -ErrorAction Stop
        }
        
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
            Write-Host "  ✓ PASSATO (Status: $($response.StatusCode))" -ForegroundColor Green
            $script:testPassati++
            return $response.Content | ConvertFrom-Json
        } else {
            Write-Host "  ✗ FALLITO (Status: $($response.StatusCode))" -ForegroundColor Red
            $script:errori++
            return $null
        }
    } catch {
        Write-Host "  ✗ ERRORE: $($_.Exception.Message)" -ForegroundColor Red
        $script:errori++
        return $null
    }
}

# 1. Health Check
Write-Host "1. Health Check" -ForegroundColor Cyan
Test-Endpoint -Method "GET" -Url "$BASE_URL/up" -Description "Health check endpoint"

# 2. Test Toni
Write-Host "2. Test API Toni" -ForegroundColor Cyan
$toni = Test-Endpoint -Method "GET" -Url "$BASE_URL/toni?company_id=1" -Description "Recupero lista toni"
if ($toni) {
    Write-Host "  Toni trovati: $($toni.tones.Count)" -ForegroundColor Gray
}

# 3. Test Conversazioni
Write-Host "3. Test API Conversazioni" -ForegroundColor Cyan
$conversazioni = Test-Endpoint -Method "GET" -Url "$BASE_URL/conversazioni?company_id=1" -Description "Recupero lista conversazioni"
if ($conversazioni) {
    Write-Host "  Conversazioni trovate: $($conversazioni.Count)" -ForegroundColor Gray
}

# 4. Test Generazione Testo (se ci sono toni)
Write-Host "4. Test Generazione Testo AI" -ForegroundColor Cyan
if ($toni -and $toni.tones.Count -gt 0) {
    $primoTono = $toni.tones[0].name
    $body = @{
        prompt = "Scrivi una breve email di presentazione"
        tone = $primoTono
        company_id = 1
    }
    $generazione = Test-Endpoint -Method "POST" -Url "$BASE_URL/genera" -Description "Generazione testo con AI" -Body $body
    if ($generazione -and $generazione.text) {
        Write-Host "  Testo generato: $($generazione.text.Substring(0, [Math]::Min(50, $generazione.text.Length)))..." -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠ Saltato (nessun tono disponibile)" -ForegroundColor Yellow
}

# 5. Test Documenti (lista)
Write-Host "5. Test API Documenti" -ForegroundColor Cyan
$documents = Test-Endpoint -Method "GET" -Url "$BASE_URL/documents?company_id=1" -Description "Recupero lista documenti"
if ($documents) {
    Write-Host "  Documenti trovati: $($documents.Count)" -ForegroundColor Gray
}

# Riepilogo
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Riepilogo Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test passati: $testPassati" -ForegroundColor Green
Write-Host "Test falliti: $errori" -ForegroundColor $(if ($errori -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($errori -eq 0) {
    Write-Host "✓ Tutti i test sono passati!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Per testare manualmente:" -ForegroundColor Yellow
    Write-Host "  - Generazione testo: http://localhost:3000/tester.html" -ForegroundColor White
    Write-Host "  - Analisi documenti: http://localhost:3000/documentTester.html" -ForegroundColor White
} else {
    Write-Host "✗ Alcuni test sono falliti. Controlla:" -ForegroundColor Red
    Write-Host "  1. Il backend è in esecuzione su $BASE_URL?" -ForegroundColor White
    Write-Host "  2. Il database è inizializzato?" -ForegroundColor White
    Write-Host "  3. Le credenziali AWS sono configurate?" -ForegroundColor White
}
Write-Host ""

