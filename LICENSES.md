# Tương Thích Giấy Phép (License Compatibility)

Tài liệu này mô tả các thư viện và dependencies được sử dụng trong dự án EcoCheck, cùng với giấy phép của chúng và xác nhận tương thích với MIT License.

## 📜 Giấy Phép Dự Án

**EcoCheck** được cấp phép dưới **MIT License**.

Xem file [LICENSE](LICENSE) để biết toàn văn giấy phép.

---

## 🎯 Mục Đích Giấy Phép MIT

Dự án chọn MIT License vì:

1. **Tính Tương Thích Cao**: MIT License tương thích với hầu hết các giấy phép mã nguồn mở khác
2. **Đơn Giản và Rõ Ràng**: Giấy phép ngắn gọn, dễ hiểu, không có điều khoản phức tạp
3. **Phù Hợp với Mục Tiêu**: Cho phép sử dụng thương mại và chỉnh sửa tự do, phù hợp với mục tiêu phát triển Smart City
4. **Khuyến Khích Đóng Góp**: Giấy phép permissive khuyến khích cộng đồng đóng góp và tái sử dụng mã nguồn

---

## 📦 Dependencies và Giấy Phép

### Backend Dependencies (Node.js)

| Package | Version | License | Tương Thích MIT | Ghi Chú |
|---------|---------|---------|-----------------|---------|
| express | ^4.18.2 | MIT | ✅ | Framework web |
| socket.io | ^4.7.5 | MIT | ✅ | Real-time communication |
| pg | ^8.11.3 | MIT | ✅ | PostgreSQL client |
| axios | ^1.6.0 | MIT | ✅ | HTTP client |
| bcrypt | ^6.0.0 | MIT | ✅ | Password hashing |
| cors | ^2.8.5 | MIT | ✅ | CORS middleware |
| compression | ^1.7.4 | MIT | ✅ | Compression middleware |
| dotenv | ^16.3.1 | MIT | ✅ | Environment variables |
| multer | ^2.0.2 | MIT | ✅ | File upload |
| node-cron | ^3.0.3 | ISC | ✅ | Cron jobs |
| arima | ^0.2.5 | MIT | ✅ | Time series forecasting |
| uuid | ^9.0.1 | MIT | ✅ | UUID generation |

**Tổng kết Backend**: ✅ Tất cả dependencies đều tương thích với MIT License

---

### Frontend Web Dependencies (React)

| Package | Version | License | Tương Thích MIT | Ghi Chú |
|---------|---------|---------|-----------------|---------|
| react | ^19.2.0 | MIT | ✅ | UI library |
| react-dom | ^19.2.0 | MIT | ✅ | React DOM renderer |
| react-router-dom | ^7.0.2 | MIT | ✅ | Routing |
| socket.io-client | ^4.7.5 | MIT | ✅ | WebSocket client |
| maplibre-gl | ^3.6.2 | ISC | ✅ | Map library |
| react-icons | ^5.5.0 | MIT | ✅ | Icon library |
| vite | ^7.2.4 | MIT | ✅ | Build tool |

**Tổng kết Frontend Web**: ✅ Tất cả dependencies đều tương thích với MIT License

---

### Frontend Mobile Dependencies (Flutter/Dart)

#### EcoCheck_Worker

| Package | Version | License | Tương Thích MIT | Ghi Chú |
|---------|---------|---------|-----------------|---------|
| flutter_bloc | ^8.1.3 | MIT | ✅ | State management |
| dio | ^5.4.0 | MIT | ✅ | HTTP client |
| socket_io_client | ^2.0.3+1 | MIT | ✅ | WebSocket client |
| geolocator | ^11.0.0 | MIT | ✅ | Location services |
| flutter_map | ^7.0.2 | BSD 3-Clause | ✅ | OpenStreetMap rendering |
| flutter_map_tile_caching | ^10.0.2 | BSD 3-Clause | ✅ | Offline map caching |
| latlong2 | ^0.9.1 | Apache 2.0 | ✅ | Geographic calculations |
| image_picker | ^1.0.7 | MIT | ✅ | Image picker |
| shared_preferences | ^2.2.2 | BSD 3-Clause | ✅ | Local storage |
| flutter_secure_storage | ^9.0.0 | MIT | ✅ | Secure storage |

#### EcoCheck_User

| Package | Version | License | Tương Thích MIT | Ghi Chú |
|---------|---------|---------|-----------------|---------|
| flutter_bloc | ^8.1.3 | MIT | ✅ | State management |
| dio | ^5.3.3 | MIT | ✅ | HTTP client |
| socket_io_client | ^2.0.3+1 | MIT | ✅ | WebSocket client |
| geolocator | ^10.1.0 | MIT | ✅ | Location services |
| flutter_map | ^7.0.2 | BSD 3-Clause | ✅ | OpenStreetMap rendering |
| flutter_map_tile_caching | ^10.0.2 | BSD 3-Clause | ✅ | Offline map caching |
| latlong2 | ^0.9.1 | Apache 2.0 | ✅ | Geographic calculations |
| shared_preferences | ^2.2.2 | BSD 3-Clause | ✅ | Local storage |
| google_generative_ai | ^0.2.2 | Apache-2.0 | ✅ | Google Gemini AI SDK |

**Tổng kết Frontend Mobile**: ✅ Tất cả dependencies đều tương thích với MIT License

**Lưu ý về Apache 2.0 và BSD 3-Clause**:
- Apache 2.0 và BSD 3-Clause đều tương thích với MIT License
- Có thể sử dụng trong dự án MIT mà không có xung đột

---

### Infrastructure & Tools

| Tool/Service | License | Tương Thích MIT | Ghi Chú |
|--------------|---------|-----------------|---------|
| Node.js | MIT | ✅ | Runtime |
| PostgreSQL | PostgreSQL License | ✅ | Database (tương đương BSD) |
| PostGIS | GPL v2 | ⚠️ | Extension (runtime, không bundle) |
| TimescaleDB | Apache 2.0 | ✅ | Extension |
| Redis | BSD 3-Clause | ✅ | Cache |
| Docker | Apache 2.0 | ✅ | Containerization |
| Flutter | BSD 3-Clause | ✅ | Mobile framework |
| Git | GPL v2 | ✅ | Version control (tool, không bundle) |

**Lưu ý về GPL v2 (PostGIS, Git)**:
- PostGIS và Git là **tools/runtime**, không được bundle vào mã nguồn
- Sử dụng chúng không yêu cầu license dự án phải là GPL
- Chỉ cần đảm bảo không bundle mã nguồn GPL vào dự án

---

## ✅ Xác Nhận Tương Thích

### Không Có Xung Đột Giấy Phép

Sau khi kiểm tra toàn bộ dependencies:

1. ✅ **Tất cả thư viện JavaScript/Node.js**: MIT hoặc ISC (tương thích)
2. ✅ **Tất cả thư viện React**: MIT (tương thích)
3. ✅ **Tất cả thư viện Flutter**: MIT, Apache 2.0, hoặc BSD 3-Clause (tương thích)
4. ✅ **Infrastructure tools**: Không bundle vào mã nguồn, chỉ sử dụng runtime

### Các Giấy Phép Tương Thích với MIT

Các giấy phép sau đây **tương thích hoàn toàn** với MIT License:

- ✅ **MIT License**: Tương thích 100%
- ✅ **ISC License**: Tương thích 100% (tương đương MIT)
- ✅ **Apache 2.0**: Tương thích 100%
- ✅ **BSD 2-Clause**: Tương thích 100%
- ✅ **BSD 3-Clause**: Tương thích 100%
- ✅ **PostgreSQL License**: Tương thích 100% (tương đương BSD)

### Các Giấy Phép Cần Lưu Ý

- ⚠️ **GPL v2** (PostGIS, Git): Chỉ sử dụng runtime, không bundle
- ⚠️ **ODbL** (OpenStreetMap data): Chỉ đọc dữ liệu, không sửa đổi

---

## 📋 Checklist Tương Thích

- [x] Tất cả dependencies đã được kiểm tra
- [x] Không có giấy phép xung đột
- [x] Tất cả thư viện đều có giấy phép tương thích
- [x] Infrastructure tools không được bundle vào mã nguồn
- [x] Dữ liệu từ nguồn mở tuân thủ giấy phép tương ứng

---

## 🔍 Cách Kiểm Tra Giấy Phép Dependencies

### Node.js (Backend & Frontend Web)

```bash
# Kiểm tra giấy phép của tất cả packages
cd backend
npm list --depth=0 | grep -E "MIT|ISC|Apache|BSD"

# Hoặc sử dụng license-checker
npx license-checker --summary
```

### Flutter (Mobile)

```bash
# Kiểm tra giấy phép
cd frontend-mobile/EcoCheck_Worker
flutter pub deps --style=tree | grep -E "MIT|Apache|BSD"
```

---

## 📚 Tài Liệu Tham Khảo

- [MIT License](https://opensource.org/licenses/MIT)
- [License Compatibility](https://en.wikipedia.org/wiki/License_compatibility)
- [Choose a License](https://choosealicense.com/)
- [SPDX License List](https://spdx.org/licenses/)

---

## ⚖️ Tuyên Bố Pháp Lý

Dự án EcoCheck đã thực hiện đánh giá kỹ lưỡng về tương thích giấy phép:

1. **Tất cả dependencies** đều có giấy phép tương thích với MIT
2. **Không có xung đột giấy phép** trong mã nguồn
3. **Dữ liệu từ nguồn mở** được sử dụng tuân thủ giấy phép tương ứng
4. **Infrastructure tools** (PostGIS, Git) chỉ sử dụng runtime, không bundle

Nếu phát hiện bất kỳ vấn đề về giấy phép, vui lòng báo cáo qua [GitHub Issues](https://github.com/Lil5354/EcoCheck-OLP-2025/issues).

---

**Last Updated**: 2025-01-28  
**Version**: 1.0.0  
**Maintained by**: EcoCheck Development Team

