# Script hướng dẫn và hỗ trợ cài đặt Flutter
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Flutter Installation Helper" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Flutter đã cài chưa
Write-Host "[1/5] Kiểm tra Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Flutter đã được cài đặt!" -ForegroundColor Green
        flutter --version
        Write-Host ""
        Write-Host "Bạn có thể chạy mobile app ngay bây giờ!" -ForegroundColor Green
        exit 0
    }
} catch {
    Write-Host "❌ Flutter chưa được cài đặt" -ForegroundColor Red
}

Write-Host ""

# Kiểm tra Flutter đã tải về chưa
Write-Host "[2/5] Tìm Flutter đã tải về..." -ForegroundColor Yellow

# Tìm file ZIP Flutter trên ổ E
Write-Host "Đang tìm Flutter trên ổ E..." -ForegroundColor Cyan
$flutterZip = Get-ChildItem -Path E:\ -Recurse -Filter "flutter*.zip" -ErrorAction SilentlyContinue -Depth 2 | Select-Object -First 1

if ($flutterZip) {
    Write-Host "✅ Tìm thấy file ZIP: $($flutterZip.FullName)" -ForegroundColor Green
    Write-Host "Đang giải nén Flutter..." -ForegroundColor Yellow
    
    $extractPath = "E:\flutter"
    if (-not (Test-Path $extractPath)) {
        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
    }
    
    # Giải nén file ZIP
    Expand-Archive -Path $flutterZip.FullName -DestinationPath $extractPath -Force
    Write-Host "✅ Đã giải nén Flutter vào: $extractPath" -ForegroundColor Green
    
    # Tìm thư mục flutter bên trong (nếu giải nén tạo thư mục con)
    $flutterDir = Get-ChildItem -Path $extractPath -Directory -Filter "flutter" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($flutterDir) {
        $flutterPath = $flutterDir.FullName
    } else {
        $flutterPath = $extractPath
    }
} else {
    # Tìm thư mục Flutter đã giải nén
    $commonPaths = @(
        "E:\flutter",
        "E:\flutter\flutter",
        "C:\flutter",
        "C:\src\flutter",
        "$env:USERPROFILE\flutter",
        "$env:LOCALAPPDATA\flutter",
        "D:\flutter"
    )
    
    $flutterPath = $null
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $flutterExe = Join-Path $path "bin\flutter.bat"
            if (Test-Path $flutterExe) {
                $flutterPath = $path
                Write-Host "✅ Tìm thấy Flutter tại: $path" -ForegroundColor Green
                break
            }
        }
    }
}

# Kiểm tra Flutter có tồn tại không
$flutterFound = $false
if ($flutterPath) {
    $flutterExe = Join-Path $flutterPath "bin\flutter.bat"
    if (Test-Path $flutterExe) {
        $flutterFound = $true
    }
}

if ($flutterFound) {
    Write-Host ""
    Write-Host "[3/5] Thêm Flutter vào PATH..." -ForegroundColor Yellow
    
    $binPath = Join-Path $flutterPath "bin"
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -notlike "*$binPath*") {
        Write-Host "Đang thêm $binPath vào PATH..." -ForegroundColor Cyan
        
        # Thêm vào PATH cho session hiện tại
        $env:Path += ";$binPath"
        
        # Thêm vào PATH vĩnh viễn
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$binPath", "User")
        
        Write-Host "✅ Đã thêm Flutter vào PATH!" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  Vui lòng đóng và mở lại terminal để PATH có hiệu lực" -ForegroundColor Yellow
        Write-Host "   Hoặc chạy: `$env:Path += `";$binPath`"" -ForegroundColor Gray
        Write-Host ""
        
        # Test Flutter
        Write-Host "[4/5] Kiểm tra Flutter..." -ForegroundColor Yellow
        & "$binPath\flutter.bat" --version
        
        Write-Host ""
        Write-Host "[5/5] Chạy flutter doctor..." -ForegroundColor Yellow
        & "$binPath\flutter.bat" doctor
        
    } else {
        Write-Host "✅ Flutter đã có trong PATH" -ForegroundColor Green
    }
    
} else {
    Write-Host "❌ Flutter chưa được tải về" -ForegroundColor Red
    Write-Host ""
    Write-Host "[3/5] Hướng dẫn tải và cài đặt Flutter:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📥 BƯỚC 1: Tải Flutter SDK" -ForegroundColor Cyan
    Write-Host "   URL: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor White
    Write-Host "   Hoặc tải trực tiếp: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.x.x-stable.zip" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📦 BƯỚC 2: Giải nén" -ForegroundColor Cyan
    Write-Host "   Giải nén vào: C:\flutter" -ForegroundColor White
    Write-Host "   (Không giải nén vào C:\Program Files\ hoặc thư mục cần quyền admin)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔧 BƯỚC 3: Thêm vào PATH" -ForegroundColor Cyan
    Write-Host "   - Mở 'Environment Variables'" -ForegroundColor White
    Write-Host "   - Thêm: C:\flutter\bin vào PATH" -ForegroundColor White
    Write-Host "   - Hoặc chạy lại script này sau khi giải nén" -ForegroundColor White
    Write-Host ""
    Write-Host "✅ BƯỚC 4: Kiểm tra" -ForegroundColor Cyan
    Write-Host "   flutter doctor" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 TIP: Sau khi tải về và giải nén, chạy lại script này!" -ForegroundColor Yellow
    Write-Host ""
    
    # Mở trình duyệt để tải Flutter
    Write-Host "Đang mở trang tải Flutter trong trình duyệt..." -ForegroundColor Cyan
    Start-Process "https://flutter.dev/docs/get-started/install/windows"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Hoàn tất!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""


