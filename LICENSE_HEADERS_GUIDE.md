# Hướng Dẫn Thêm License Headers

Tài liệu này hướng dẫn cách thêm license header MIT vào tất cả các file nguồn trong dự án.

## 📋 Yêu Cầu

Theo tiêu chí chấm điểm OLP 2025:
- ✅ **Bắt buộc**: Giấy phép phải được ghi trong từng tệp mã
- ⚠️ **Rủi ro**: -10 PoF nếu không có license header trong từng file

## 🎯 Format License Header

### Cho JavaScript/TypeScript Files (.js, .jsx, .ts, .tsx)

```javascript
/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * [Mô tả ngắn về file này]
 */
```

### Cho Dart Files (.dart)

```dart
/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck [Worker/User] - [Mô tả ngắn về file]
 */
```

### Cho SQL Files (.sql)

```sql
-- MIT License
-- Copyright (c) 2025 Lil5354
-- [Mô tả ngắn về file]
```

## 🚀 Cách Thêm License Headers

### Option 1: Sử Dụng Script Tự Động (Khuyến nghị)

#### Windows (PowerShell)

```powershell
# Chạy script để thêm license headers vào tất cả file Dart
.\scripts\add-license-headers.ps1
```

#### Linux/Mac (Bash)

```bash
# Cấp quyền thực thi
chmod +x scripts/add-license-headers.sh

# Chạy script
./scripts/add-license-headers.sh
```

**Lưu ý**: Script sẽ tự động:
- Bỏ qua các file đã có license header
- Thêm header vào đầu file (trước import statements)
- Xử lý cả Worker và User apps

### Option 2: Thêm Thủ Công

1. **Mở file cần thêm header**
2. **Thêm license header ở dòng đầu tiên** (trước tất cả import/statements)
3. **Lưu file**

**Ví dụ:**

**Trước:**
```dart
import 'package:flutter/material.dart';
// ... rest of code
```

**Sau:**
```dart
/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Worker - Main application entry point
 */

import 'package:flutter/material.dart';
// ... rest of code
```

## 📁 Files Cần Thêm License Header

### Backend (Node.js)
- ✅ Đã có: `backend/src/index.js`, `orionld.js`, `realtime.js`, và các service files
- ⚠️ Cần kiểm tra: Các file trong `backend/src/` còn lại (nếu có)

### Frontend Web (React)
- ✅ Đã có: 25/39 files có license header
- ⚠️ Cần thêm: ~14 files còn lại trong `frontend-web-manager/src/`

### Frontend Mobile (Flutter)
- ✅ Đã có: `main.dart`, `api_constants.dart`, `injection_container.dart` (đã thêm)
- ⚠️ Cần thêm: Tất cả các file `.dart` còn lại trong `lib/` (sử dụng script tự động)

**Số lượng file cần xử lý:**
- EcoCheck_Worker: ~73 files
- EcoCheck_User: ~78 files
- **Tổng**: ~151 files

## 🔍 Kiểm Tra License Headers

### Kiểm tra file đã có header chưa

```bash
# Windows PowerShell
Select-String -Path "frontend-mobile\EcoCheck_Worker\lib\*.dart" -Pattern "MIT License"

# Linux/Mac
grep -r "MIT License" frontend-mobile/EcoCheck_Worker/lib/
```

### Đếm số file đã có header

```bash
# Windows PowerShell
(Select-String -Path "frontend-mobile\EcoCheck_Worker\lib\*.dart" -Pattern "MIT License" -List).Count

# Linux/Mac
grep -r -l "MIT License" frontend-mobile/EcoCheck_Worker/lib/ | wc -l
```

## ✅ Checklist

Sau khi thêm license headers, kiểm tra:

- [ ] Tất cả file `.js`, `.jsx` trong `backend/src/` đã có header
- [ ] Tất cả file `.jsx` trong `frontend-web-manager/src/` đã có header
- [ ] Tất cả file `.dart` trong `frontend-mobile/EcoCheck_Worker/lib/` đã có header
- [ ] Tất cả file `.dart` trong `frontend-mobile/EcoCheck_User/lib/` đã có header
- [ ] Các file SQL trong `db/migrations/` đã có header (nếu cần)

## 🎯 Ưu Tiên

1. **Ưu tiên cao**: Các file chính (main.dart, api_constants.dart, injection_container.dart) - ✅ Đã hoàn thành
2. **Ưu tiên cao**: Sử dụng script tự động để thêm vào tất cả file Dart - ✅ Script đã được tạo
3. **Ưu tiên trung bình**: Thêm vào các file Frontend Web còn thiếu
4. **Ưu tiên thấp**: Thêm vào các file SQL (nếu cần)

## 📝 Lưu Ý

- Script tự động sẽ **bỏ qua** các file đã có license header
- Script sẽ **không ghi đè** nội dung file, chỉ thêm header ở đầu
- Nếu file đã có comment ở đầu, script sẽ thêm header trước comment đó

## 🔗 Liên Kết

- [MIT License](https://opensource.org/licenses/MIT)
- [License Headers Best Practices](https://opensource.guide/legal/#what-does-the-license-file-do)

---

**Last Updated**: 2025-01-28  
**Version**: 1.0.0

