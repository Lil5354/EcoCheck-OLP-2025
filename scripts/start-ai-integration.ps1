# MIT License
# Copyright (c) 2025 Lil5354
# Script to start EcoCheck system with AI integration

Write-Host "🚀 Starting EcoCheck System with AI Integration..." -ForegroundColor Green

# Step 1: Check and setup .env file
Write-Host "`n📝 Step 1: Setting up environment variables..." -ForegroundColor Cyan
if (-not (Test-Path "backend\.env")) {
    Copy-Item "backend\env.example" "backend\.env"
    Write-Host "✅ Created .env file from env.example" -ForegroundColor Green
} else {
    Write-Host "✅ .env file already exists" -ForegroundColor Green
}

# Step 2: Start Docker services (PostgreSQL)
Write-Host "`n🐳 Step 2: Starting Docker services..." -ForegroundColor Cyan
$dockerStatus = docker-compose ps --format json | ConvertFrom-Json
$postgresRunning = $dockerStatus | Where-Object { $_.Service -eq "postgres" -and $_.State -eq "running" }

if (-not $postgresRunning) {
    Write-Host "Starting PostgreSQL container..." -ForegroundColor Yellow
    docker-compose up -d postgres
    Write-Host "⏳ Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
} else {
    Write-Host "✅ PostgreSQL is already running" -ForegroundColor Green
}

# Step 3: Install backend dependencies
Write-Host "`n📦 Step 3: Installing backend dependencies..." -ForegroundColor Cyan
Set-Location backend
if (-not (Test-Path "node_modules")) {
    npm install
    Write-Host "✅ Backend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✅ Backend dependencies already installed" -ForegroundColor Green
}

# Step 4: Start backend server
Write-Host "`n🔧 Step 4: Starting backend server..." -ForegroundColor Cyan
Write-Host "Backend will start on http://localhost:3000" -ForegroundColor Yellow
Write-Host "AI endpoints:" -ForegroundColor Yellow
Write-Host "  - POST /api/ai/analyze-image" -ForegroundColor Yellow
Write-Host "  - POST /api/user/checkin" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop the backend server" -ForegroundColor Yellow
Write-Host ""

# Start backend in background
$backendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD\backend
    $env:NODE_ENV = "development"
    npm start
}

# Wait a bit for backend to start
Start-Sleep -Seconds 5

# Check if backend is running
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Backend is running!" -ForegroundColor Green
    Write-Host "   Health check: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Backend may still be starting..." -ForegroundColor Yellow
    Write-Host "   Check http://localhost:3000/health manually" -ForegroundColor Yellow
}

# Step 5: Instructions for mobile app
Write-Host "`n📱 Step 5: Mobile App Setup" -ForegroundColor Cyan
Write-Host "To start the mobile app:" -ForegroundColor Yellow
Write-Host "  1. Open a new terminal" -ForegroundColor White
Write-Host "  2. Navigate to: frontend-mobile/EcoCheck_User" -ForegroundColor White
Write-Host "  3. Run: flutter run" -ForegroundColor White
Write-Host ""
Write-Host "The mobile app is configured to connect to:" -ForegroundColor Yellow
Write-Host "  - Backend: http://10.0.2.2:3000 (Android emulator)" -ForegroundColor White
Write-Host "  - Backend: http://localhost:3000 (iOS simulator)" -ForegroundColor White
Write-Host ""

# Step 6: Test endpoints
Write-Host "`n🧪 Step 6: Testing AI Integration" -ForegroundColor Cyan
Write-Host "You can test the AI endpoints using:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Test AI Analysis (requires image URL):" -ForegroundColor White
Write-Host '   curl -X POST http://localhost:3000/api/ai/analyze-image \' -ForegroundColor Gray
Write-Host '     -H "Content-Type: application/json" \' -ForegroundColor Gray
Write-Host '     -d "{\"image_url\": \"YOUR_IMAGE_URL\"}"' -ForegroundColor Gray
Write-Host ""
Write-Host "2. Test User Check-in:" -ForegroundColor White
Write-Host '   curl -X POST http://localhost:3000/api/user/checkin \' -ForegroundColor Gray
Write-Host '     -H "Content-Type: application/json" \' -ForegroundColor Gray
Write-Host '     -d "{\"user_id\": \"...\", \"waste_type\": \"household\", \"filling_level\": 0.5, \"latitude\": 10.7769, \"longitude\": 106.6958}"' -ForegroundColor Gray
Write-Host ""

# Keep script running
Write-Host "✅ System is ready!" -ForegroundColor Green
Write-Host "Backend logs are running in background job." -ForegroundColor Yellow
Write-Host "To view backend logs: Get-Job | Receive-Job" -ForegroundColor Yellow
Write-Host "To stop backend: Stop-Job -Id $($backendJob.Id)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to exit and stop backend..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Cleanup
Write-Host "`n🛑 Stopping backend..." -ForegroundColor Yellow
Stop-Job -Id $backendJob.Id
Remove-Job -Id $backendJob.Id
Set-Location ..
Write-Host "✅ Backend stopped" -ForegroundColor Green

