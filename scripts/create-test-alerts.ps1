# CN7 Test Alert Generator (PowerShell)
# This script creates test alerts for the Dynamic Dispatch feature

Write-Host "🚀 CN7 Test Alert Generator" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$BackendUrl = "http://localhost:3000"

# Check if backend is running
Write-Host "1️⃣  Checking if backend is running..." -ForegroundColor Yellow
try {
    $healthCheck = Invoke-RestMethod -Uri "$BackendUrl/health" -Method Get -ErrorAction Stop
    Write-Host "✅ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend is not running at $BackendUrl" -ForegroundColor Red
    Write-Host "   Please start the backend first:" -ForegroundColor Yellow
    Write-Host "   docker compose up -d backend" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Start test route
Write-Host "2️⃣  Starting test route..." -ForegroundColor Yellow
$body = @{
    route_id = "test-route-001"
    vehicle_id = "V01"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BackendUrl/api/test/start-route" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body `
        -ErrorAction Stop
    
    if ($response.ok) {
        Write-Host "✅ Test route started successfully" -ForegroundColor Green
        Write-Host "   Route ID: test-route-001" -ForegroundColor Gray
        Write-Host "   Vehicle: V01" -ForegroundColor Gray
        Write-Host "   Points: $($response.points -join ', ')" -ForegroundColor Gray
    } else {
        Write-Host "❌ Failed to start test route" -ForegroundColor Red
        Write-Host "   Response: $($response | ConvertTo-Json)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error starting test route: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Wait for cron job to detect missed points
Write-Host "3️⃣  Waiting for missed point detection..." -ForegroundColor Yellow
Write-Host "   The cron job runs every 15 seconds..." -ForegroundColor Gray
for ($i = 1; $i -le 20; $i++) {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 1
}
Write-Host ""

# Check if alerts were created
Write-Host ""
Write-Host "4️⃣  Checking for alerts..." -ForegroundColor Yellow
try {
    $alerts = Invoke-RestMethod -Uri "$BackendUrl/api/alerts" -Method Get -ErrorAction Stop
    
    if ($alerts.data -and $alerts.data.Count -gt 0) {
        Write-Host "✅ Alerts created successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 Alert Details:" -ForegroundColor Cyan
        $alerts.data | Format-Table -AutoSize
    } else {
        Write-Host "⚠️  No alerts detected yet" -ForegroundColor Yellow
        Write-Host "   This might mean:" -ForegroundColor Gray
        Write-Host "   - The cron job hasn't run yet (wait a bit longer)" -ForegroundColor Gray
        Write-Host "   - The vehicle is not far enough from the points" -ForegroundColor Gray
        Write-Host "   - There's an issue with the detection logic" -ForegroundColor Gray
        Write-Host ""
        Write-Host "   Raw response:" -ForegroundColor Gray
        Write-Host "   $($alerts | ConvertTo-Json -Depth 5)" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Error checking alerts: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open the Dynamic Dispatch page:" -ForegroundColor White
Write-Host "   http://localhost:3001/operations/dynamic-dispatch" -ForegroundColor Gray
Write-Host ""
Write-Host "2. If no alerts appear, wait another 15 seconds and refresh" -ForegroundColor White
Write-Host ""
Write-Host "3. Check backend logs:" -ForegroundColor White
Write-Host "   docker logs ecocheck-backend --tail 50" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Manually check database:" -ForegroundColor White
Write-Host "   docker exec -it ecocheck-postgres psql -U ecocheck_user -d ecocheck -c 'SELECT * FROM alerts;'" -ForegroundColor Gray
Write-Host ""

