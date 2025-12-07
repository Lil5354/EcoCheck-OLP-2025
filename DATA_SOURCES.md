# Nguồn Dữ Liệu Mở (Open Data Sources)

Tài liệu này mô tả các nguồn dữ liệu mở được sử dụng trong dự án EcoCheck, bao gồm giấy phép và cách tích hợp.

## 📊 Tổng Quan

Dự án EcoCheck sử dụng kết hợp dữ liệu thật từ các API công khai và dữ liệu giả lập (mock data) được tạo ra để phục vụ mục đích demo và kiểm thử.

---

## 🌍 Dữ Liệu Thật (Real Data)

### 1. OpenWeatherMap - Dữ Liệu Thời Tiết

**Mô tả:**
- Cung cấp dữ liệu thời tiết thời gian thực và dự báo
- Sử dụng để tối ưu hóa lộ trình thu gom dựa trên điều kiện thời tiết
- Tích hợp vào thuật toán VRP để tính toán điểm số thời tiết (weather score)

**API:**
- **Endpoint**: `https://api.openweathermap.org/data/2.5/weather`
- **Documentation**: https://openweathermap.org/api
- **API Key**: Cần đăng ký tại https://openweathermap.org/api_keys

**Giấy phép:**
- **License**: [Creative Commons Attribution-ShareAlike 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
- **Terms of Service**: https://openweathermap.org/terms
- **Tương thích với MIT**: ✅ Có (CC BY-SA 4.0 cho phép sử dụng thương mại và chỉnh sửa)

**Cách sử dụng trong dự án:**
- Backend gọi API khi tối ưu lộ trình
- Dữ liệu được cache để tránh rate limiting
- Fallback về mock data nếu API không khả dụng

**Vị trí trong code:**
- `backend/src/index.js` - Route optimization với weather integration

---

### 2. OpenAQ - Dữ Liệu Chất Lượng Không Khí

**Mô tả:**
- Cung cấp dữ liệu chất lượng không khí (AQI) từ các trạm quan trắc trên toàn thế giới
- Sử dụng để hiển thị AQI trên dashboard và đưa ra khuyến nghị sức khỏe

**API:**
- **Endpoint**: `https://api.openaq.org/v3/latest`
- **Documentation**: https://docs.openaq.org/
- **API Key**: ✅ Yêu cầu (API v3 yêu cầu API key authentication)
- **API Key Header**: `X-API-Key`

**Giấy phép:**
- **License**: [CC0 1.0 Universal (Public Domain)](https://creativecommons.org/publicdomain/zero/1.0/)
- **Terms**: https://openaq.org/#/terms
- **Tương thích với MIT**: ✅ Có (CC0 là public domain, hoàn toàn tương thích)

**Cách sử dụng trong dự án:**
- Backend gọi API khi người dùng xem trang Air Quality
- Dữ liệu được cache trong memory (1 giờ)
- Sử dụng API key từ biến môi trường `AIRQUALITY_API_KEY`
- Tự động mở rộng bán kính tìm kiếm nếu không tìm thấy dữ liệu (5km → 10km → 250km)
- Fallback về mock data nếu API không khả dụng hoặc không có API key

**Vị trí trong code:**
- `backend/src/index.js` - Air quality endpoints

---

### 3. OpenStreetMap (OSM) - Dữ Liệu Địa Lý và POI

**Mô tả:**
- Cung cấp dữ liệu bản đồ, địa điểm, và Points of Interest (POI) miễn phí
- Sử dụng cho:
  - Geocoding (chuyển đổi địa chỉ ↔ tọa độ) qua Nominatim
  - Tìm kiếm POI (trạm xăng, nhà hàng, bãi đỗ xe) qua Overpass API
  - Tính toán ma trận khoảng cách qua OSRM

**APIs:**
- **Nominatim** (Geocoding): `https://nominatim.openstreetmap.org/`
- **Overpass API** (POI): `https://overpass-api.de/api/interpreter`
- **OSRM** (Routing): `http://router.project-osrm.org/route/v1/`

**Documentation:**
- Nominatim: https://nominatim.org/release-docs/latest/
- Overpass: https://wiki.openstreetmap.org/wiki/Overpass_API
- OSRM: http://project-osrm.org/

**Giấy phép:**
- **License**: [Open Database License (ODbL) 1.0](https://opendatacommons.org/licenses/odbl/)
- **Attribution**: Yêu cầu ghi công OpenStreetMap contributors
- **Tương thích với MIT**: ⚠️ Cần lưu ý (ODbL yêu cầu "Share-Alike" - nếu sửa đổi dữ liệu OSM, phải chia sẻ lại dưới ODbL)

**Lưu ý quan trọng:**
- Dự án EcoCheck **KHÔNG sửa đổi dữ liệu OSM**, chỉ **đọc và hiển thị**
- Do đó, không có yêu cầu Share-Alike
- Chỉ cần ghi công (attribution) khi hiển thị bản đồ

**Cách sử dụng trong dự án:**
- Nominatim: Geocoding địa chỉ trong check-in
- Overpass: Tìm POI dọc theo route
- OSRM: Tính toán ma trận khoảng cách cho VRP

**Vị trí trong code:**
- `backend/src/index.js` - POI endpoints, route optimization

---

## 🎭 Dữ Liệu Giả Lập (Mock Data)

### 1. Sensor Data - Dữ Liệu Cảm Biến Thùng Rác

**Mô tả:**
- Dữ liệu về mức đầy của thùng rác (filling level) được tạo ra để demo
- Mô phỏng dữ liệu từ cảm biến IoT thực tế
- Tuân thủ chuẩn SOSA/SSN (W3C) và NGSI-LD (ETSI)

**Nguồn:**
- Tự tạo bởi nhóm phát triển
- Dựa trên cấu trúc Smart Data Models của FIWARE
- Seed data trong `db/migrations/` và `seeds/ngsi-ld/`

**Giấy phép:**
- **License**: MIT License (theo giấy phép của dự án)
- **Copyright**: Copyright (c) 2025 Lil5354
- **Tương thích**: ✅ Hoàn toàn tương thích (dữ liệu tự tạo)

**Vị trí trong code:**
- `db/migrations/` - SQL seed scripts
- `seeds/ngsi-ld/cn14/` - JSON-LD context files

---

### 2. Collection Points - Điểm Thu Gom Rác

**Mô tả:**
- Dữ liệu về các điểm thu gom rác tại TP.HCM (mô phỏng)
- Bao gồm tọa độ, loại điểm, lịch sử check-in
- Dữ liệu được tạo dựa trên cấu trúc thực tế của TP.HCM

**Nguồn:**
- Tự tạo bởi nhóm phát triển
- Tham khảo cấu trúc thực tế của hệ thống thu gom rác tại TP.HCM
- Seed data trong `db/seed_data.sql`

**Giấy phép:**
- **License**: MIT License (theo giấy phép của dự án)
- **Copyright**: Copyright (c) 2025 Lil5354
- **Tương thích**: ✅ Hoàn toàn tương thích (dữ liệu tự tạo)

**Vị trí trong code:**
- `db/seed_data.sql` - Seed data cho collection points

---

### 3. Vehicle & Personnel Data - Dữ Liệu Xe và Nhân Viên

**Mô tả:**
- Dữ liệu về đội xe thu gom và nhân viên (mô phỏng)
- Bao gồm thông số kỹ thuật xe, lịch làm việc, routes

**Nguồn:**
- Tự tạo bởi nhóm phát triển
- Seed data trong `db/seed_worker_schedules.sql`

**Giấy phép:**
- **License**: MIT License (theo giấy phép của dự án)
- **Copyright**: Copyright (c) 2025 Lil5354
- **Tương thích**: ✅ Hoàn toàn tương thích (dữ liệu tự tạo)

---

## 📋 Tổng Kết Giấy Phép

| Nguồn Dữ Liệu | Giấy Phép | Tương Thích MIT | Yêu Cầu Attribution |
|---------------|-----------|-----------------|---------------------|
| OpenWeatherMap | CC BY-SA 4.0 | ✅ Có | ✅ Có |
| OpenAQ | CC0 1.0 | ✅ Có | Không bắt buộc |
| OpenStreetMap | ODbL 1.0 | ⚠️ Có (chỉ đọc) | ✅ Có |
| Mock Data (Sensor, Points, Vehicles) | MIT | ✅ Có | Không |

---

## 🔗 Liên Kết Hữu Ích

- [OpenWeatherMap Terms](https://openweathermap.org/terms)
- [OpenAQ Terms](https://openaq.org/#/terms)
- [OpenStreetMap License](https://www.openstreetmap.org/copyright)
- [ODbL License](https://opendatacommons.org/licenses/odbl/)
- [FIWARE Smart Data Models](https://smartdatamodels.org)

---

## 📝 Ghi Chú Quan Trọng

1. **Attribution**: Khi sử dụng dữ liệu từ OpenStreetMap, cần hiển thị attribution: "© OpenStreetMap contributors"

2. **Rate Limiting**: 
   - OpenWeatherMap: Có giới hạn số lần gọi API (tùy gói)
   - OpenAQ: Không có rate limit nghiêm ngặt
   - Nominatim: Yêu cầu tôn trọng [Usage Policy](https://operations.osmfoundation.org/policies/nominatim/)

3. **Dữ Liệu Thực Tế**: 
   - Dự án hiện tại sử dụng mock data cho demo
   - Trong triển khai thực tế, cần tích hợp với các nguồn dữ liệu thật từ cơ quan quản lý nhà nước

4. **Tuân Thủ Giấy Phép**: 
   - Tất cả dữ liệu sử dụng đều tuân thủ giấy phép tương ứng
   - Không có xung đột giấy phép với MIT License của dự án

---

**Last Updated**: 2025-01-28  
**Version**: 1.0.0

