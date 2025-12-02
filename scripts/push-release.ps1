# push-release.ps1
# Script để push code và tag lên GitHub cho release

$VERSION = "1.0.0"
$TAG = "v$VERSION"
$BRANCH = "TWeb"  # Thay đổi nếu branch của bạn khác

Write-Host "🚀 Pushing release $TAG to GitHub..." -ForegroundColor Green
Write-Host ""

# Kiểm tra xem có thay đổi chưa commit không
$status = git status --porcelain
if ($status) {
    Write-Host "⚠️  Có thay đổi chưa commit. Bạn có muốn commit không? (y/n)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "y") {
        Write-Host "📝 Committing changes..." -ForegroundColor Cyan
        git add .
        git commit -m "chore: prepare for $TAG release"
    }
}

# Kiểm tra xem tag đã tồn tại chưa
$existingTag = git tag -l $TAG
if ($existingTag) {
    Write-Host "✅ Tag $TAG đã tồn tại local" -ForegroundColor Green
} else {
    Write-Host "❌ Tag $TAG chưa tồn tại. Vui lòng tạo tag trước." -ForegroundColor Red
    Write-Host "   Chạy: git tag -a $TAG -m 'Release message'" -ForegroundColor Yellow
    exit 1
}

# Push code
Write-Host "📤 Pushing code to origin/$BRANCH..." -ForegroundColor Cyan
try {
    git push origin $BRANCH
    Write-Host "✅ Code đã được push thành công!" -ForegroundColor Green
} catch {
    Write-Host "❌ Lỗi khi push code: $_" -ForegroundColor Red
    exit 1
}

# Push tag
Write-Host "📤 Pushing tag $TAG to GitHub..." -ForegroundColor Cyan
try {
    git push origin $TAG
    Write-Host "✅ Tag đã được push thành công!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Thử push tất cả tags..." -ForegroundColor Yellow
    git push origin --tags
}

Write-Host ""
Write-Host "✅ Hoàn thành! Tag và code đã được push lên GitHub." -ForegroundColor Green
Write-Host ""
Write-Host "📝 Bước tiếp theo:" -ForegroundColor Yellow
Write-Host "1. Truy cập: https://github.com/Lil5354/EcoCheck-OLP-2025/releases/new" -ForegroundColor White
Write-Host "2. Chọn tag: $TAG" -ForegroundColor White
Write-Host "3. Copy nội dung từ RELEASE_NOTES.md" -ForegroundColor White
Write-Host "4. Click 'Publish release'" -ForegroundColor White
Write-Host ""
Write-Host "Xem huong dan chi tiet trong file: GITHUB_RELEASE_GUIDE.md" -ForegroundColor Cyan

