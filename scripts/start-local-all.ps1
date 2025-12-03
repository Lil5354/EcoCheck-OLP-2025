# Script khoi chay tat ca: Database, Backend, Frontend va mo browser
# EcoCheck OLP 2025 - Local Development

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ECOCHECK - KHOI CHAY LOCAL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Tinh duong dan root project
$projectRoot = Split-Path -Parent $PSScriptRoot

# Buoc 1: Kiem tra Docker
Write-Host "[1/5] Kiem tra Docker..." -ForegroundColor Yellow
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker chua duoc cai dat!" -ForegroundColor Red
    Write-Host "   Vui long cai dat Docker Desktop" -ForegroundColor Red
    exit 1
}

$dockerRunning = docker info 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker Desktop chua chay!" -ForegroundColor Red
    Write-Host "   Vui long khoi dong Docker Desktop" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Docker dang chay" -ForegroundColor Green
Write-Host ""

# Buoc 2: Khoi dong Database
Write-Host "[2/5] Khoi dong Database (PostgreSQL)..." -ForegroundColor Yellow
Set-Location $projectRoot
docker compose up -d postgres

# Doi database san sang
Write-Host "Dang doi database khoi dong..." -ForegroundColor Cyan
$maxRetries = 30
$retryCount = 0
$dbReady = $false

while ($retryCount -lt $maxRetries -and -not $dbReady) {
    Start-Sleep -Seconds 2
    $dbCheck = docker compose exec -T postgres pg_isready -U ecocheck_user 2>$null
    if ($LASTEXITCODE -eq 0) {
        $dbReady = $true
        Write-Host "OK: Database da san sang" -ForegroundColor Green
    } else {
        $retryCount++
        Write-Host "   Dang doi... ($retryCount/$maxRetries)" -ForegroundColor Gray
    }
}

if (-not $dbReady) {
    Write-Host "WARNING: Database chua san sang, nhung se tiep tuc..." -ForegroundColor Yellow
}
Write-Host ""

# Buoc 3: Kiem tra Node.js
Write-Host "[3/5] Kiem tra Node.js..." -ForegroundColor Yellow
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js chua duoc cai dat!" -ForegroundColor Red
    Write-Host "   Vui long cai dat Node.js tu https://nodejs.org/" -ForegroundColor Red
    exit 1
}
$nodeVersion = node --version
Write-Host "OK: Node.js $nodeVersion" -ForegroundColor Green
Write-Host ""

# Buoc 4: Kiem tra dependencies
Write-Host "[4/5] Kiem tra dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "$projectRoot\backend\node_modules")) {
    Write-Host "Dang cai dat backend dependencies..." -ForegroundColor Cyan
    Push-Location "$projectRoot\backend"
    npm install
    Pop-Location
}
if (-not (Test-Path "$projectRoot\frontend-web-manager\node_modules")) {
    Write-Host "Dang cai dat frontend dependencies..." -ForegroundColor Cyan
    Push-Location "$projectRoot\frontend-web-manager"
    npm install
    Pop-Location
}
Write-Host "OK: Dependencies da san sang" -ForegroundColor Green
Write-Host ""

# Buoc 5: Khoi chay Backend va Frontend
Write-Host "[5/5] Khoi chay Backend va Frontend..." -ForegroundColor Yellow
Write-Host ""

# Thiet lap bien moi truong cho backend
$env:NODE_ENV = "development"
$env:PORT = "3000"
$env:DATABASE_URL = "postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck"
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
$env:DB_USER = "ecocheck_user"
$env:DB_PASSWORD = "ecocheck_pass"
$env:DB_NAME = "ecocheck"
$env:ORION_LD_URL = "http://localhost:1026"

# Khoi chay Backend trong terminal moi
Write-Host "Khoi chay Backend tren http://localhost:3000" -ForegroundColor Green
$backendCmd = "cd '$projectRoot\backend'; `$env:NODE_ENV='development'; `$env:PORT='3000'; `$env:DATABASE_URL='postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck'; `$env:DB_HOST='localhost'; `$env:DB_PORT='5432'; `$env:DB_USER='ecocheck_user'; `$env:DB_PASSWORD='ecocheck_pass'; `$env:DB_NAME='ecocheck'; npm run dev"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd -WindowStyle Normal

# Doi backend khoi dong
Start-Sleep -Seconds 5

# Khoi chay Frontend trong terminal moi
Write-Host "Khoi chay Frontend Web tren http://localhost:5173" -ForegroundColor Green
$frontendCmd = "cd '$projectRoot\frontend-web-manager'; npm run dev"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $frontendCmd -WindowStyle Normal

# Doi frontend khoi dong
Start-Sleep -Seconds 8

# Mo trinh duyet
Write-Host "Mo trinh duyet..." -ForegroundColor Green
Start-Process "http://localhost:5173"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DA KHOI CHAY TAT CA!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Database:   localhost:5432/ecocheck" -ForegroundColor Yellow
Write-Host "Backend:    http://localhost:3000" -ForegroundColor Yellow
Write-Host "Frontend:   http://localhost:5173" -ForegroundColor Yellow
Write-Host ""
Write-Host "Cac terminal da duoc mo rieng biet:" -ForegroundColor Cyan
Write-Host "   - Terminal Backend (port 3000)" -ForegroundColor Gray
Write-Host "   - Terminal Frontend (port 5173)" -ForegroundColor Gray
Write-Host ""
Write-Host "De dung:" -ForegroundColor Cyan
Write-Host "   - Dong cac terminal windows" -ForegroundColor Gray
Write-Host "   - Hoac chay: docker compose down" -ForegroundColor Gray
Write-Host ""
