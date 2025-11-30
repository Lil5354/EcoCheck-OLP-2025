# Script test kết nối Backend từ Web và Mobile
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EcoCheck - Connection Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testUrls = @(
    @{ Name = "Backend Health (localhost)"; Url = "http://localhost:3000/health" },
    @{ Name = "Backend API Status"; Url = "http://localhost:3000/api/status" },
    @{ Name = "Frontend Web"; Url = "http://localhost:3001" }
)

$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*" 
} | Select-Object -First 1).IPAddress

if ($localIP) {
    $testUrls += @{ Name = "Backend Health (Local IP)"; Url = "http://$localIP:3000/health" }
}

$allPassed = $true

foreach ($test in $testUrls) {
    Write-Host "Testing: $($test.Name)..." -ForegroundColor Yellow
    Write-Host "  URL: $($test.Url)" -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $test.Url -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✅ PASSED (Status: $($response.StatusCode))" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $allPassed = $false
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "  ✅ All tests passed!" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Some tests failed" -ForegroundColor Yellow
    Write-Host "  Kiểm tra Docker services: docker compose ps" -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test mobile endpoints
Write-Host "Testing Mobile Endpoints..." -ForegroundColor Cyan
Write-Host ""

$mobileEndpoints = @(
    "/api/auth/login",
    "/api/schedules/assigned",
    "/api/routes/active"
)

foreach ($endpoint in $mobileEndpoints) {
    $url = "http://localhost:3000$endpoint"
    Write-Host "  $endpoint" -ForegroundColor Gray
    try {
        $response = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 3 -UseBasicParsing -ErrorAction SilentlyContinue
        Write-Host "    ✅ Endpoint exists" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 400 -or $statusCode -eq 401) {
            Write-Host "    ✅ Endpoint exists (requires auth/params)" -ForegroundColor Green
        } else {
            Write-Host "    ⚠️  Status: $statusCode" -ForegroundColor Yellow
        }
    }
}

Write-Host ""



