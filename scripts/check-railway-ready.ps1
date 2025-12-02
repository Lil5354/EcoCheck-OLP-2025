# MIT License
# Copyright (c) 2025 Lil5354
# Script kiểm tra xem dự án đã sẵn sàng deploy Railway chưa (PowerShell)

Write-Host "🔍 Kiểm tra sẵn sàng deploy Railway..." -ForegroundColor Cyan
Write-Host ""

$ERRORS = 0

# Check files
Write-Host "📁 Kiểm tra files cần thiết..." -ForegroundColor Yellow

if (Test-Path "Dockerfile.railway") {
    Write-Host "✅ Dockerfile.railway" -ForegroundColor Green
} else {
    Write-Host "❌ Thiếu Dockerfile.railway" -ForegroundColor Red
    $ERRORS++
}

if (Test-Path "railway.toml") {
    Write-Host "✅ railway.toml" -ForegroundColor Green
} else {
    Write-Host "❌ Thiếu railway.toml" -ForegroundColor Red
    $ERRORS++
}

if (Test-Path "backend/entrypoint.sh") {
    Write-Host "✅ backend/entrypoint.sh" -ForegroundColor Green
} else {
    Write-Host "❌ Thiếu backend/entrypoint.sh" -ForegroundColor Red
    $ERRORS++
}

# Check git
Write-Host ""
Write-Host "🔗 Kiểm tra Git..." -ForegroundColor Yellow

if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "✅ Git đã cài" -ForegroundColor Green
    $remotes = git remote -v 2>$null
    if ($remotes -match "github.com") {
        Write-Host "✅ Đã có GitHub remote" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Chưa có GitHub remote" -ForegroundColor Yellow
        Write-Host "   Chạy: git remote add origin https://github.com/Lil5354/EcoCheck-OLP-2025.git" -ForegroundColor Gray
    }
} else {
    Write-Host "❌ Git chưa cài" -ForegroundColor Red
    $ERRORS++
}

# Check Dockerfile content
Write-Host ""
Write-Host "🐳 Kiểm tra Dockerfile.railway..." -ForegroundColor Yellow

if (Test-Path "Dockerfile.railway") {
    $content = Get-Content "Dockerfile.railway" -Raw
    if ($content -match "FROM node") {
        Write-Host "✅ Dockerfile hợp lệ" -ForegroundColor Green
    } else {
        Write-Host "❌ Dockerfile không hợp lệ" -ForegroundColor Red
        $ERRORS++
    }
}

# Summary
Write-Host ""
if ($ERRORS -eq 0) {
    Write-Host "✅✅✅ SẴN SÀNG DEPLOY RAILWAY! ✅✅✅" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Bước tiếp theo:" -ForegroundColor Cyan
    Write-Host "  1. Truy cập: https://railway.app"
    Write-Host "  2. Login với GitHub"
    Write-Host "  3. New Project → Deploy from GitHub repo"
    Write-Host "  4. Chọn: Lil5354/EcoCheck-OLP-2025"
    Write-Host ""
    Write-Host "📚 Xem hướng dẫn chi tiết: DEPLOY_RAILWAY.md" -ForegroundColor Cyan
} else {
    Write-Host "❌ Có $ERRORS lỗi. Vui lòng sửa trước khi deploy." -ForegroundColor Red
}
