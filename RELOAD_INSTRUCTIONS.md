# Hướng dẫn xem thay đổi marker START/END

## Code đã được cập nhật thành công ✅

File: `frontend-web-manager/src/pages/operations/RouteOptimization.jsx`

### Thay đổi:
- **Điểm bắt đầu (START)**: Hình vuông bo tròn, màu xanh lá (#059669), text "START"
- **Điểm kết thúc (END)**: Hình tròn, màu đỏ (#dc2626), text "END"

## Cách xem thay đổi:

### Bước 1: Hard Refresh trình duyệt
1. Nhấn **Ctrl+Shift+R** (hoặc Ctrl+F5)
2. Hoặc mở DevTools (F12) → Network tab → Check "Disable cache" → Refresh

### Bước 2: Render lại route trên bản đồ
1. Vào trang "Tối ưu tuyến đường"
2. Chọn quận và tối ưu route
3. **Quan trọng**: Nhấn lại nút **"Xem bản đồ"** để render lại với code mới
   - Route đã render trước đó sẽ vẫn dùng code cũ
   - Cần render lại để thấy marker mới

### Bước 3: Kiểm tra Console
- Mở DevTools (F12) → Console
- Xem log: `[RouteOptimization] Added depot marker`
- Nếu thấy log này, code đã chạy

## Nếu vẫn chưa thấy:

Restart frontend dev server:
1. Tìm terminal đang chạy frontend (npm run dev)
2. Nhấn Ctrl+C để dừng
3. Chạy lại: `npm run dev` trong thư mục `frontend-web-manager`

