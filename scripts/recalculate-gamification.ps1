# Recalculate Gamification Levels and Badges
$backendUrl = "http://localhost:3000"

Write-Host "========================================" -ForegroundColor Green
Write-Host "Recalculating Gamification Levels and Badges" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Checking backend connection..." -ForegroundColor Yellow
try {
    $null = Invoke-WebRequest -Uri "$backendUrl/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✓ Backend is running" -ForegroundColor Green
}
catch {
    Write-Host "✗ Backend is not running at $backendUrl" -ForegroundColor Red
    Write-Host "Please start the backend server first."
    exit 1
}

Write-Host ""
Write-Host "Calling API: POST /api/gamification/recalculate/all" -ForegroundColor Yellow
Write-Host ""

$response = $null
try {
    $response = Invoke-WebRequest -Uri "$backendUrl/api/gamification/recalculate/all" -Method POST -ContentType "application/json" -TimeoutSec 300 -ErrorAction Stop
}
catch {
    Write-Host "✗ Error calling API: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($response -ne $null) {
    $data = $response.Content | ConvertFrom-Json
    
    if ($data.ok) {
        Write-Host "✓ Recalculation completed!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Results:" -ForegroundColor Cyan
        Write-Host "  Users updated: $($data.data.usersUpdated)" -ForegroundColor White
        Write-Host "  Badges unlocked: $($data.data.badgesUnlocked)" -ForegroundColor White
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
    }
    else {
        Write-Host "✗ Failed: $($data.error)" -ForegroundColor Red
        exit 1
    }
}
