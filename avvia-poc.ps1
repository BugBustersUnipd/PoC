# Script PowerShell per avviare il POC completo (Backend + Frontend)
# Utilizzo: .\avvia-poc.ps1
# Questo script apre due finestre separate per Backend e Frontend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Avvio POC Nexum (Backend + Frontend)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Get-Location
}

# Avvia Backend in una nuova finestra
Write-Host "Avvio Backend Rails in una nuova finestra..." -ForegroundColor Green
$backendScript = Join-Path $scriptDir "avvia-backend.ps1"
Start-Process powershell.exe -ArgumentList "-NoExit", "-File", "`"$backendScript`"" -WorkingDirectory $scriptDir

# Attendi un po' prima di avviare il frontend
Start-Sleep -Seconds 2

# Avvia Frontend in una nuova finestra
Write-Host "Avvio Frontend Angular in una nuova finestra..." -ForegroundColor Green
$frontendScript = Join-Path $scriptDir "avvia-frontend.ps1"
Start-Process powershell.exe -ArgumentList "-NoExit", "-File", "`"$frontendScript`"" -WorkingDirectory $scriptDir

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  POC Avviato con Successo!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Due finestre sono state aperte:" -ForegroundColor Yellow
Write-Host "  - Finestra 1: Backend Rails (porta 3000)" -ForegroundColor White
Write-Host "  - Finestra 2: Frontend Angular (porta 4200)" -ForegroundColor White
Write-Host ""
Write-Host "URL disponibili:" -ForegroundColor Cyan
Write-Host "  Backend Rails:  http://localhost:3000" -ForegroundColor Yellow
Write-Host "  Frontend Angular: http://localhost:4200" -ForegroundColor Yellow
Write-Host ""
Write-Host "Per arrestare i servizi, chiudi le finestre aperte" -ForegroundColor Yellow
Write-Host ""
Write-Host "Premi un tasto per chiudere questo messaggio..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

