# Tính năng: Chú thích Bản đồ và Nhãn Dữ liệu Biểu đồ

## Tổng quan
Bổ sung chú thích (legend) cho bản đồ và hiển thị chú thích số liệu (data labels) cho các biểu đồ trên Dashboard chính, tuân thủ đúng CN5 và quy tắc cuộc thi.

## Thay đổi chính

### 1. Map Legend (Chú thích Bản đồ)
**File:** `frontend-web-manager/src/components/RealtimeMap.jsx`

#### Tính năng:
- Hiển thị chú thích 4 trạng thái điểm thu gom theo CN5:
  - **Grey (#9aa0a6)**: Điểm "ma" (Không rác)
  - **Green (var(--success))**: Rác ít/vừa
  - **Yellow (var(--warning))**: Rác nhiều
  - **Red (var(--danger))**: Rác cồng kềnh/Sự cố

#### Vị trí:
- Hiển thị ngay bên dưới bản đồ
- Không che khuất Attribution của OSM/MapLibre

#### Responsive:
- Tự động điều chỉnh kích thước trên màn hình nhỏ
- Legend items xuống dòng khi cần thiết

### 2. AreaChart Data Labels (Nhãn Dữ liệu Biểu đồ Vùng)
**File:** `frontend-web-manager/src/components/Charts.jsx`

#### Props mới:
```javascript
{
  showLabels: true,           // Bật/tắt hiển thị nhãn (default: true)
  labelEvery: 2,              // Hiển thị nhãn mỗi N điểm (default: 2)
  labelFormatter: (value, index) => string  // Tùy chỉnh định dạng nhãn
}
```

#### Tính năng:
- Hiển thị giá trị tại các điểm dữ liệu
- Sampling để tránh lộn xộn (mặc định mỗi 2 điểm)
- Tự động ẩn nhãn khi màn hình < 480px
- Định dạng số theo locale vi-VN

#### Ví dụ sử dụng:
```jsx
<AreaChart 
  data={timeseries} 
  color="var(--primary)" 
  stroke={3}
  showLabels={true}
  labelEvery={2}
  labelFormatter={(value) => `${value.toFixed(0)}t`}
/>
```

### 3. DonutChart Data Labels (Nhãn Dữ liệu Biểu đồ Tròn)
**File:** `frontend-web-manager/src/components/Charts.jsx`

#### Props mới:
```javascript
{
  showLabels: true,                    // Bật/tắt hiển thị nhãn (default: true)
  labelPosition: 'outside',            // 'outside' | 'inside' (default: 'outside')
  minAngleForLabel: 0.15,              // Góc tối thiểu để hiển thị nhãn (radians)
  numberFormatter: (value) => string   // Tùy chỉnh định dạng số
}
```

#### Tính năng:
- Hiển thị phần trăm và giá trị cho từng lát cắt
- Leader lines khi labelPosition='outside'
- Tự động ẩn nhãn cho các lát quá nhỏ (< minAngleForLabel)
- Hiển thị tổng ở giữa vòng tròn
- Định dạng số theo locale vi-VN

#### Ví dụ sử dụng:
```jsx
<DonutChart 
  segments={byType} 
  colors={['var(--success)','var(--accent)','var(--danger)']}
  showLabels={true}
  labelPosition="outside"
  minAngleForLabel={0.15}
  numberFormatter={(value) => `${value.toFixed(1)}t`}
/>
```

### 4. CSS Improvements
**File:** `frontend-web-manager/src/index.css`

#### Thay đổi:
- Cải thiện `.legend-color`: tăng kích thước lên 12px, thêm border và shadow
- Thêm `.map-container` để wrap map và legend
- Thêm `.chart-label` cho styling nhãn biểu đồ
- Responsive breakpoints cho legend (768px, 480px)

## Tuân thủ Quy tắc Cuộc thi

✅ **Bản đồ**: Dùng MapLibre/OSM, hiển thị Attribution  
✅ **Không PII**: Chỉ dữ liệu mô phỏng  
✅ **Không dịch vụ thương mại**: Không dùng API trả phí  
✅ **Tiếng Việt**: Giao diện và định dạng số theo vi-VN  
✅ **CN5**: Màu sắc đúng theo quy định (grey, green, yellow, red)  

## Kiểm thử

### Desktop (> 768px):
1. Mở http://localhost:3001
2. Xác nhận:
   - Map legend hiển thị 4 trạng thái với đúng màu
   - AreaChart có nhãn giá trị tại các điểm (mỗi 2 điểm)
   - DonutChart có nhãn % và giá trị, tổng hiển thị ở center

### Mobile (< 480px):
1. Thu nhỏ trình duyệt hoặc dùng DevTools responsive mode
2. Xác nhận:
   - Legend vẫn hiển thị, items xuống dòng hợp lý
   - AreaChart labels tự động ẩn
   - DonutChart labels vẫn hiển thị (nếu đủ chỗ)

### Console:
- Không có lỗi JavaScript
- Network requests bình thường

## Rollback (Nếu cần)

Nếu có vấn đề, rollback về checkpoint:
```bash
git log --oneline  # Tìm commit "CHECKPOINT: Before adding map legend and chart data labels"
git reset --hard <commit-hash>
docker compose up -d --no-deps --build frontend-web
```

## Screenshots

### Desktop View
![Desktop Dashboard](./docs/screenshots/dashboard-desktop-with-labels.png)

### Mobile View
![Mobile Dashboard](./docs/screenshots/dashboard-mobile-with-labels.png)

## Tác giả
- **Branch**: TWeb
- **Commit**: [Xem git log]
- **Ngày**: 2025-11-23

