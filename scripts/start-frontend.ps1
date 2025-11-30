# Start Frontend Server
$projectRoot = Split-Path -Parent $PSScriptRoot
Write-Host "🚀 Starting EcoCheck Frontend..." -ForegroundColor Green
Set-Location "$projectRoot\frontend-web-manager"
npm run dev

