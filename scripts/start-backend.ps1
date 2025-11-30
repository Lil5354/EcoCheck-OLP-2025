# Start Backend Server
$projectRoot = Split-Path -Parent $PSScriptRoot
Write-Host "🚀 Starting EcoCheck Backend..." -ForegroundColor Green
Set-Location "$projectRoot\backend"
$env:NODE_ENV = "development"
npm run dev

