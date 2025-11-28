# Script mở terminal mới để chạy Mobile App
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Khởi chạy Mobile App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Flutter
$flutterFound = $false
$flutterPath = $null

# Kiểm tra trong PATH
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0) {
        $flutterFound = $true
        Write-Host "✅ Flutter đã được cài đặt" -ForegroundColor Green
    }
} catch {
    # Kiểm tra các đường dẫn thông thường
    $commonPaths = @(
        "C:\flutter\bin\flutter.bat",
        "C:\src\flutter\bin\flutter.bat",
        "$env:USERPROFILE\flutter\bin\flutter.bat"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $flutterPath = $path
            $flutterFound = $true
            Write-Host "✅ Tìm thấy Flutter tại: $path" -ForegroundColor Green
            break
        }
    }
}

if (-not $flutterFound) {
    Write-Host "❌ Flutter chưa được cài đặt!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Vui lòng cài đặt Flutter:" -ForegroundColor Yellow
    Write-Host "1. Tải từ: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor White
    Write-Host "2. Giải nén vào C:\flutter" -ForegroundColor White
    Write-Host "3. Thêm C:\flutter\bin vào PATH" -ForegroundColor White
    Write-Host "4. Chạy lại script này" -ForegroundColor White
    Write-Host ""
    Write-Host "Hoặc mở terminal và chạy thủ công:" -ForegroundColor Cyan
    Write-Host "  cd E:\EcoCheck-OLP-2025\frontend-mobile\EcoCheck_Worker" -ForegroundColor Yellow
    Write-Host "  flutter run" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Mở terminal mới để chạy Flutter
Write-Host "Đang mở terminal mới để chạy Mobile App..." -ForegroundColor Cyan
Write-Host ""

$mobilePath = "E:\EcoCheck-OLP-2025\frontend-mobile\EcoCheck_Worker"

Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$mobilePath'; Write-Host '========================================' -ForegroundColor Cyan; Write-Host '  EcoCheck Mobile App' -ForegroundColor Cyan; Write-Host '========================================' -ForegroundColor Cyan; Write-Host ''; Write-Host 'Đang kiểm tra devices...' -ForegroundColor Yellow; flutter devices; Write-Host ''; Write-Host 'Đang khởi chạy app...' -ForegroundColor Yellow; flutter run"

Write-Host "✅ Đã mở terminal mới!" -ForegroundColor Green
Write-Host "Mobile app đang được khởi chạy trong terminal đó." -ForegroundColor Green
Write-Host ""



