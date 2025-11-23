# Hướng dẫn Sử dụng Chart Labels và Map Legend

## 1. AreaChart - Biểu đồ Vùng với Data Labels

### Props cơ bản
```jsx
import { AreaChart } from './components/Charts.jsx'

<AreaChart 
  data={timeseries}           // Array of {value: number} or number[]
  color="var(--primary)"      // Màu đường và gradient
  stroke={3}                  // Độ dày đường
  width={520}                 // Chiều rộng (default: 520)
  height={140}                // Chiều cao (default: 140)
  gradient={true}             // Hiển thị gradient (default: true)
/>
```

### Props cho Data Labels
```jsx
<AreaChart 
  data={timeseries}
  
  // Bật/tắt labels
  showLabels={true}           // default: true
  
  // Hiển thị label mỗi N điểm (tránh lộn xộn)
  labelEvery={2}              // default: 2
  
  // Tùy chỉnh format label
  labelFormatter={(value, index) => {
    return value.toLocaleString('vi-VN', { maximumFractionDigits: 0 }) + 't'
  }}
/>
```

### Ví dụ thực tế
```jsx
// Hiển thị tất cả labels
<AreaChart 
  data={[62, 58, 65, 59, 60, 62, 64, 61, 58, 56, 59, 63]}
  showLabels={true}
  labelEvery={1}
  labelFormatter={(v) => `${v}t`}
/>

// Chỉ hiển thị mỗi 3 điểm
<AreaChart 
  data={timeseries}
  labelEvery={3}
/>

// Tắt labels hoàn toàn
<AreaChart 
  data={timeseries}
  showLabels={false}
/>
```

### Responsive Behavior
- **Desktop (≥ 480px)**: Labels hiển thị theo `labelEvery`
- **Mobile (< 480px)**: Labels tự động ẩn để tránh lộn xộn

---

## 2. DonutChart - Biểu đồ Tròn với Data Labels

### Props cơ bản
```jsx
import { DonutChart } from './components/Charts.jsx'

<DonutChart 
  segments={{                 // Object với key-value pairs
    'Sinh hoạt': 45,
    'Tái chế': 28,
    'Cồng kềnh': 15
  }}
  colors={[                   // Mảng màu tương ứng
    'var(--success)',
    'var(--accent)',
    'var(--danger)'
  ]}
  size={140}                  // Kích thước (default: 140)
/>
```

### Props cho Data Labels
```jsx
<DonutChart 
  segments={byType}
  
  // Bật/tắt labels
  showLabels={true}                    // default: true
  
  // Vị trí label: 'outside' hoặc 'inside'
  labelPosition='outside'              // default: 'outside'
  
  // Góc tối thiểu để hiển thị label (radians)
  // Lát nhỏ hơn góc này sẽ không hiển thị label
  minAngleForLabel={0.15}              // default: 0.15 (~8.6 degrees)
  
  // Tùy chỉnh format số
  numberFormatter={(value) => {
    return value.toLocaleString('vi-VN', { maximumFractionDigits: 1 }) + 't'
  }}
/>
```

### Ví dụ thực tế
```jsx
// Labels bên ngoài với leader lines
<DonutChart 
  segments={{ 'Sinh hoạt': 45, 'Tái chế': 28, 'Cồng kềnh': 15 }}
  colors={['var(--success)', 'var(--accent)', 'var(--danger)']}
  labelPosition="outside"
/>

// Labels bên trong
<DonutChart 
  segments={byType}
  labelPosition="inside"
/>

// Ẩn labels cho lát nhỏ (< 10 degrees)
<DonutChart 
  segments={byType}
  minAngleForLabel={0.174}  // ~10 degrees
/>

// Tắt labels, chỉ hiển thị tổng ở center
<DonutChart 
  segments={byType}
  showLabels={false}
/>
```

### Label Components
Khi `showLabels={true}`:
- **Outside labels**: Phần trăm + giá trị + leader line
- **Inside labels**: Chỉ phần trăm
- **Center**: Hiển thị "Tổng: XXt"

---

## 3. Map Legend - Chú thích Bản đồ

### Sử dụng trong RealtimeMap
```jsx
import { Legend } from './components/Charts.jsx'

const mapLegendItems = [
  { label: 'Không rác (Điểm ma)', color: '#9aa0a6' },
  { label: 'Rác ít/vừa', color: 'var(--success)' },
  { label: 'Rác nhiều', color: 'var(--warning)' },
  { label: 'Rác cồng kềnh/Sự cố', color: 'var(--danger)' }
]

return (
  <div className="map-container">
    <div className="map-root" ref={mapRef} />
    <Legend items={mapLegendItems} />
  </div>
)
```

### Sử dụng độc lập
```jsx
<Legend items={[
  { label: 'Hoàn thành', color: 'var(--success)' },
  { label: 'Đang xử lý', color: 'var(--warning)' },
  { label: 'Lỗi', color: 'var(--danger)' }
]} />
```

### Responsive Behavior
- **Desktop (> 768px)**: Legend hiển thị trên 1 hàng
- **Tablet (768px)**: Font size giảm xuống 11px
- **Mobile (< 480px)**: Items xuống dòng, gap giảm

---

## 4. Accessibility (A11y)

### Chart Labels
- `user-select: none` để tránh chọn text
- `pointer-events: none` để không can thiệp tương tác

### Legend
- Kích thước `.legend-color` >= 12px (đạt yêu cầu WCAG)
- Độ tương phản màu đạt chuẩn
- Có thể thêm `aria-label` cho từng item nếu cần

---

## 5. Performance Tips

### AreaChart
- Sử dụng `labelEvery` để giảm số lượng DOM elements
- Tự động ẩn labels trên mobile để cải thiện performance

### DonutChart
- `minAngleForLabel` giúp tránh render labels không cần thiết
- Leader lines chỉ render khi `labelPosition='outside'`

---

## 6. Troubleshooting

### Labels không hiển thị
1. Kiểm tra `showLabels={true}`
2. Kiểm tra viewport width (AreaChart ẩn labels < 480px)
3. Kiểm tra `minAngleForLabel` (DonutChart)

### Labels bị chồng chéo
1. Tăng `labelEvery` cho AreaChart
2. Tăng `minAngleForLabel` cho DonutChart
3. Giảm số lượng data points

### Legend không responsive
1. Kiểm tra CSS breakpoints trong `index.css`
2. Đảm bảo `.legend` có `flex-wrap: wrap`

