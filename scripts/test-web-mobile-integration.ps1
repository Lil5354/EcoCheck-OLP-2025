# Script test liên kết dữ liệu giữa Web và Mobile
# EcoCheck OLP 2025
# Chạy cả Web và Mobile cùng lúc để test tính liên kết dữ liệu

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TEST LIÊN KẾT DỮ LIỆU WEB + MOBILE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptPath) { $scriptPath = $PWD }

# 1. Kiểm tra Docker và Database
Write-Host "[1/5] Kiểm tra Database Services..." -ForegroundColor Yellow
try {
    docker ps | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker Desktop chưa chạy!" -ForegroundColor Red
        Write-Host "   Vui lòng chạy: .\setup.ps1" -ForegroundColor Yellow
        exit 1
    }
    
    # Kiểm tra backend có đang chạy không
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Backend đang chạy" -ForegroundColor Green
        } else {
            throw "Backend not ready"
        }
    } catch {
        Write-Host "⚠️  Backend chưa chạy, đang khởi động..." -ForegroundColor Yellow
        Write-Host "   Đang khởi động Docker services..." -ForegroundColor Cyan
        docker compose up -d postgres redis orion-ld backend 2>&1 | Out-Null
        Start-Sleep -Seconds 5
        
        # Đợi backend sẵn sàng
        $maxRetries = 15
        $retryCount = 0
        $backendReady = $false
        
        while ($retryCount -lt $maxRetries -and -not $backendReady) {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    $backendReady = $true
                    Write-Host "✅ Backend đã sẵn sàng!" -ForegroundColor Green
                }
            } catch {
                $retryCount++
                Write-Host "   Đang đợi backend... ($retryCount/$maxRetries)" -ForegroundColor Gray
                Start-Sleep -Seconds 2
            }
        }
        
        if (-not $backendReady) {
            Write-Host "❌ Backend chưa sẵn sàng sau $maxRetries lần thử" -ForegroundColor Red
            Write-Host "   Vui lòng chạy: .\setup.ps1" -ForegroundColor Yellow
            exit 1
        }
    }
} catch {
    Write-Host "❌ Lỗi kiểm tra Docker!" -ForegroundColor Red
    Write-Host "   Vui lòng chạy: .\setup.ps1" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 2. Khởi động Backend Server (nếu chưa chạy trong Docker)
Write-Host "[2/5] Kiểm tra Backend API Server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Backend API đang chạy tại http://localhost:3000" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Backend API chưa sẵn sàng" -ForegroundColor Yellow
    Write-Host "   Đảm bảo Docker services đang chạy: docker compose ps" -ForegroundColor Gray
}
Write-Host ""

# 3. Đợi Backend sẵn sàng (nếu cần)
Write-Host "[3/5] Đợi Backend sẵn sàng..." -ForegroundColor Yellow
$maxRetries = 15
$retryCount = 0
$backendReady = $false

while ($retryCount -lt $maxRetries -and -not $backendReady) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $backendReady = $true
            Write-Host "✅ Backend API đã sẵn sàng!" -ForegroundColor Green
        }
    } catch {
        $retryCount++
        Write-Host "   Đang đợi... ($retryCount/$maxRetries)" -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if (-not $backendReady) {
    Write-Host "⚠️  Backend chưa sẵn sàng sau $maxRetries lần thử" -ForegroundColor Yellow
    Write-Host "   Vui lòng kiểm tra cửa sổ Backend để xem lỗi" -ForegroundColor Yellow
} else {
    Write-Host "✅ Backend đã sẵn sàng để nhận kết nối!" -ForegroundColor Green
}
Write-Host ""

# 4. Khởi động Frontend Web
Write-Host "[4/5] Khởi động Frontend Web..." -ForegroundColor Yellow
$webScript = Join-Path $scriptPath "run-frontend-web.ps1"
if (Test-Path $webScript) {
    Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$webScript`""
    Write-Host "✅ Frontend Web đang khởi động trong cửa sổ riêng" -ForegroundColor Green
    Start-Sleep -Seconds 3
} else {
    Write-Host "⚠️  Không tìm thấy script run-frontend-web.ps1" -ForegroundColor Yellow
}
Write-Host ""

# 5. Khởi động Mobile App
Write-Host "[5/5] Khởi động Mobile App..." -ForegroundColor Yellow
$mobileScript = Join-Path $scriptPath "run-mobile-worker.ps1"
if (Test-Path $mobileScript) {
    Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$mobileScript`""
    Write-Host "✅ Mobile App đang khởi động trong cửa sổ riêng" -ForegroundColor Green
} else {
    Write-Host "⚠️  Không tìm thấy script run-mobile-worker.ps1" -ForegroundColor Yellow
    Write-Host "   Bạn có thể chạy mobile app thủ công:" -ForegroundColor Gray
    Write-Host "   cd frontend-mobile/EcoCheck_Worker" -ForegroundColor Gray
    Write-Host "   flutter run" -ForegroundColor Gray
}
Write-Host ""

# Hiển thị thông tin kết nối
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ TẤT CẢ SERVICES ĐÃ KHỞI ĐỘNG!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Lấy Local IP cho mobile
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*" -and
    $_.InterfaceAlias -notlike "*Loopback*"
} | Select-Object -First 1).IPAddress

if (-not $localIP) { $localIP = "localhost" }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🌐 WEB PLATFORM" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Frontend Web:  http://localhost:5173" -ForegroundColor Yellow
Write-Host "  Backend API:   http://localhost:3000" -ForegroundColor Yellow
Write-Host "  Health Check:  http://localhost:3000/health" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  📱 MOBILE PLATFORM" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Backend API:   http://localhost:3000" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Kết nối từ Mobile:" -ForegroundColor Cyan
Write-Host "    - Windows Desktop: http://localhost:3000" -ForegroundColor White
Write-Host "    - Android Emulator: http://10.0.2.2:3000" -ForegroundColor White
Write-Host "    - iOS Simulator:    http://localhost:3000" -ForegroundColor White
Write-Host "    - Real Device:      http://$localIP:3000" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🧪 HƯỚNG DẪN TEST LIÊN KẾT DỮ LIỆU" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. TEST ĐĂNG NHẬP:" -ForegroundColor Yellow
Write-Host "   - Đăng nhập trên Web: http://localhost:5173" -ForegroundColor White
Write-Host "   - Đăng nhập trên Mobile App" -ForegroundColor White
Write-Host "   - Kiểm tra: Cả 2 nền tảng đều kết nối cùng Backend" -ForegroundColor Gray
Write-Host ""
Write-Host "2. TEST ĐỒNG BỘ DỮ LIỆU:" -ForegroundColor Yellow
Write-Host "   - Tạo/Chỉnh sửa dữ liệu trên Web" -ForegroundColor White
Write-Host "   - Kiểm tra: Mobile App có nhận được dữ liệu mới không" -ForegroundColor Gray
Write-Host "   - Tạo/Chỉnh sửa dữ liệu trên Mobile" -ForegroundColor White
Write-Host "   - Kiểm tra: Web có cập nhật dữ liệu mới không" -ForegroundColor Gray
Write-Host ""
Write-Host "3. TEST REALTIME:" -ForegroundColor Yellow
Write-Host "   - Thực hiện action trên Mobile (check-in, update location)" -ForegroundColor White
Write-Host "   - Kiểm tra: Web có hiển thị realtime update không" -ForegroundColor Gray
Write-Host "   - Xem Realtime Map trên Web" -ForegroundColor White
Write-Host "   - Kiểm tra: Location từ Mobile có hiển thị trên Map không" -ForegroundColor Gray
Write-Host ""
Write-Host "4. TEST API ENDPOINTS:" -ForegroundColor Yellow
Write-Host "   - Health: http://localhost:3000/health" -ForegroundColor White
Write-Host "   - Status: http://localhost:3000/api/status" -ForegroundColor White
Write-Host "   - Schedules: http://localhost:3000/api/v1/schedules" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  📋 LƯU Ý" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  - Tất cả services chạy trong các cửa sổ PowerShell riêng" -ForegroundColor Gray
Write-Host "  - Để dừng: Đóng các cửa sổ PowerShell tương ứng" -ForegroundColor Gray
Write-Host "  - Mobile app có thể mất 2-5 phút để build lần đầu tiên" -ForegroundColor Gray
Write-Host "  - Kiểm tra console logs trong mỗi cửa sổ để debug" -ForegroundColor Gray
Write-Host "  - Đảm bảo Mobile app cấu hình đúng baseUrl trong api_constants.dart" -ForegroundColor Gray
Write-Host ""

# Kiểm tra trạng thái cuối cùng
Write-Host "Đang kiểm tra trạng thái services..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

try {
    $backendCheck = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
    if ($backendCheck.StatusCode -eq 200) {
        Write-Host "✅ Backend API: Đang chạy" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Backend: Đang khởi động..." -ForegroundColor Yellow
}

try {
    $webCheck = Invoke-WebRequest -Uri "http://localhost:5173" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
    if ($webCheck.StatusCode -eq 200) {
        Write-Host "✅ Frontend Web: Đang chạy" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Frontend Web: Đang khởi động..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🚀 SẴN SÀNG TEST!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""











