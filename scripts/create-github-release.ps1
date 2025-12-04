# create-github-release.ps1
# Script tự động tạo GitHub Release (tag + push)

$VERSION = "1.0.0"
$TAG = "v$VERSION"
$BRANCH = "DRender"  # Thay đổi nếu branch của bạn khác
$REPO = "Lil5354/EcoCheck-OLP-2025"

Write-Host "🚀 Tạo GitHub Release cho EcoCheck v$VERSION" -ForegroundColor Green
Write-Host ""

# Kiểm tra xem có thay đổi chưa commit không
$status = git status --porcelain
if ($status) {
    Write-Host "⚠️  Có thay đổi chưa commit:" -ForegroundColor Yellow
    Write-Host $status
    Write-Host ""
    Write-Host "Bạn có muốn commit tất cả thay đổi không? (y/n)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "📝 Committing changes..." -ForegroundColor Cyan
        git add .
        git commit -m "chore: prepare for $TAG release - add license headers"
        Write-Host "✅ Đã commit thành công!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Bỏ qua commit. Tiếp tục với tag..." -ForegroundColor Yellow
    }
}

# Kiểm tra xem tag đã tồn tại chưa
$existingTag = git tag -l $TAG
if ($existingTag) {
    Write-Host "⚠️  Tag $TAG đã tồn tại!" -ForegroundColor Yellow
    Write-Host "Bạn có muốn xóa và tạo lại không? (y/n)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "y" -or $response -eq "Y") {
        Write-Host "🗑️  Xóa tag cũ..." -ForegroundColor Cyan
        git tag -d $TAG
        git push origin :refs/tags/$TAG 2>$null
    } else {
        Write-Host "✅ Sử dụng tag hiện có: $TAG" -ForegroundColor Green
    }
}

# Tạo tag mới nếu chưa có
if (-not (git tag -l $TAG)) {
    Write-Host "📌 Tạo tag $TAG..." -ForegroundColor Cyan
    $releaseMessage = "EcoCheck v$VERSION - Initial Release for OLP 2025`n`n- Complete waste collection management system`n- Backend API with FIWARE Orion-LD integration`n- Web Manager Dashboard`n- Mobile Apps (Worker & User)`n- Full documentation and compliance"
    git tag -a $TAG -m $releaseMessage
    Write-Host "✅ Tag đã được tạo!" -ForegroundColor Green
} else {
    Write-Host "✅ Tag $TAG đã tồn tại" -ForegroundColor Green
}

# Push code
Write-Host ""
Write-Host "📤 Pushing code to origin/$BRANCH..." -ForegroundColor Cyan
try {
    git push origin $BRANCH
    Write-Host "✅ Code đã được push thành công!" -ForegroundColor Green
} catch {
    Write-Host "❌ Lỗi khi push code: $_" -ForegroundColor Red
    Write-Host "⚠️  Vui lòng kiểm tra kết nối và quyền truy cập GitHub" -ForegroundColor Yellow
    exit 1
}

# Push tag
Write-Host ""
Write-Host "📤 Pushing tag $TAG to GitHub..." -ForegroundColor Cyan
try {
    git push origin $TAG
    Write-Host "✅ Tag đã được push thành công!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Thử push tất cả tags..." -ForegroundColor Yellow
    git push origin --tags
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "✅ HOÀN THÀNH! Tag và code đã được push lên GitHub." -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host ""

# Đọc nội dung RELEASE_NOTES.md
$releaseNotes = ""
if (Test-Path "RELEASE_NOTES.md") {
    Write-Host "📄 Đọc nội dung từ RELEASE_NOTES.md..." -ForegroundColor Cyan
    $releaseNotes = Get-Content "RELEASE_NOTES.md" -Raw
} else {
    Write-Host "⚠️  Không tìm thấy RELEASE_NOTES.md" -ForegroundColor Yellow
    $releaseNotes = @"
# EcoCheck v$VERSION

## Initial Release for OLP 2025

### Features
- Complete waste collection management system
- Backend API with FIWARE Orion-LD integration
- Web Manager Dashboard
- Mobile Apps (Worker & User)
- Full documentation and compliance

### Documentation
- See README.md for setup instructions
- See PROJECT_STRUCTURE.md for project structure
- See COMPLIANCE_CHECKLIST.md for compliance details
"@
}

Write-Host ""
Write-Host "📝 BƯỚC TIẾP THEO - Tạo GitHub Release:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Truy cập link sau (sẽ mở trong trình duyệt):" -ForegroundColor White
Write-Host "   https://github.com/$REPO/releases/new" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Chọn tag: $TAG" -ForegroundColor White
Write-Host ""
Write-Host "3. Title: EcoCheck v$VERSION - Initial Release for OLP 2025" -ForegroundColor White
Write-Host ""
Write-Host "4. Description: Copy nội dung từ RELEASE_NOTES.md" -ForegroundColor White
Write-Host "   (Nội dung đã được lưu trong biến `$releaseNotes)" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Click 'Publish release'" -ForegroundColor White
Write-Host ""
Write-Host "📖 Xem hướng dẫn chi tiết trong: GITHUB_RELEASE_GUIDE.md" -ForegroundColor Cyan
Write-Host ""

# Hỏi xem có muốn mở link không
Write-Host "Bạn có muốn mở link tạo release trong trình duyệt không? (y/n)" -ForegroundColor Yellow
$response = Read-Host
if ($response -eq "y" -or $response -eq "Y") {
    Start-Process "https://github.com/$REPO/releases/new"
    Write-Host "✅ Đã mở trình duyệt!" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Chúc mừng! Dự án đã sẵn sàng để nộp bài!" -ForegroundColor Green

