# Hướng Dẫn Tạo GitHub Release

Tài liệu này hướng dẫn cách tạo GitHub Release cho dự án EcoCheck để đáp ứng yêu cầu của cuộc thi OLP 2025.

## 📋 Yêu Cầu

Theo tiêu chí chấm điểm:
- ✅ **Bắt buộc**: Phải có ít nhất 1 release trước thời hạn nộp bài (17:00 Thứ 2 ngày 08/12/2025)
- ✅ **Bắt buộc**: Release phải được tạo trên GitHub (không phải chỉ là tag)
- ✅ **Khuyến nghị**: Release phải có release notes rõ ràng

## 🚀 Các Bước Tạo Release

### Bước 1: Tạo Git Tag (Nếu chưa có)

```bash
# Kiểm tra tag hiện tại
git tag -l

# Tạo tag mới (nếu chưa có)
git tag -a v1.0.0 -m "EcoCheck v1.0.0 - Initial Release for OLP 2025"

# Push tag lên GitHub
git push origin v1.0.0
```

**Hoặc sử dụng script có sẵn:**

```powershell
# Windows
.\scripts\push-release.ps1

# Linux/Mac
chmod +x scripts/push-release.sh
./scripts/push-release.sh
```

### Bước 2: Tạo GitHub Release

#### Cách 1: Qua GitHub Web Interface (Khuyến nghị)

1. **Truy cập trang Releases:**
   - Vào: https://github.com/Lil5354/EcoCheck-OLP-2025/releases
   - Hoặc: Repository → **Releases** (bên phải)

2. **Tạo Release mới:**
   - Click **"Draft a new release"** hoặc **"Create a new release"**

3. **Điền thông tin:**
   - **Choose a tag**: Chọn `v1.0.0` (hoặc tạo tag mới)
   - **Release title**: `EcoCheck v1.0.0 - Initial Release for OLP 2025`
   - **Description**: Copy nội dung từ file `RELEASE_NOTES.md`

4. **Publish Release:**
   - Click **"Publish release"**

#### Cách 2: Qua GitHub CLI (Nếu đã cài gh CLI)

```bash
# Cài đặt GitHub CLI (nếu chưa có)
# Windows: winget install GitHub.cli
# Linux: sudo apt install gh
# Mac: brew install gh

# Đăng nhập
gh auth login

# Tạo release
gh release create v1.0.0 \
  --title "EcoCheck v1.0.0 - Initial Release for OLP 2025" \
  --notes-file RELEASE_NOTES.md
```

### Bước 3: Kiểm Tra Release

Sau khi tạo release, kiểm tra:

1. **Release đã được tạo:**
   - Truy cập: https://github.com/Lil5354/EcoCheck-OLP-2025/releases/tag/v1.0.0
   - Đảm bảo release hiển thị đầy đủ thông tin

2. **Tag đã được tạo:**
   - Truy cập: https://github.com/Lil5354/EcoCheck-OLP-2025/tags
   - Đảm bảo tag `v1.0.0` tồn tại

## 📝 Nội Dung Release Notes

File `RELEASE_NOTES.md` đã được tạo sẵn với nội dung đầy đủ, bao gồm:

- ✨ Tính năng chính
- 🚀 Quick Start
- 📋 System Requirements
- 🔗 Links
- 📦 What's Included
- 🎯 Use Cases
- 📝 License

**Lưu ý**: Có thể chỉnh sửa `RELEASE_NOTES.md` trước khi copy vào GitHub Release.

## ✅ Checklist Trước Khi Tạo Release

- [ ] Code đã được commit và push lên GitHub
- [ ] Tag `v1.0.0` đã được tạo và push
- [ ] File `RELEASE_NOTES.md` đã được cập nhật (nếu cần)
- [ ] Đã kiểm tra tất cả tính năng hoạt động
- [ ] Đã kiểm tra documentation đầy đủ
- [ ] Đã kiểm tra license headers trong code

## 🎯 Thời Hạn Quan Trọng

**⚠️ QUAN TRỌNG**: Release phải được tạo **TRƯỚC** thời hạn nộp bài:
- **Thời hạn nộp bài**: 17:00 Thứ 2 ngày 08/12/2025
- **Khuyến nghị**: Tạo release ít nhất 1 ngày trước thời hạn

## 🔗 Liên Kết Hữu Ích

- [GitHub Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)

---

**Last Updated**: 2025-01-28  
**Version**: 1.0.0

