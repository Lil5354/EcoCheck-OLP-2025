# Hướng dẫn xem "Cơ sở dữ liệu" mẫu cho Backend

Dự án hiện tại sử dụng dữ liệu giả lập (mock data) được lưu trong bộ nhớ thay vì một cơ sở dữ liệu thực tế để phục vụ cho mục đích phát triển. Dữ liệu này được tạo và cung cấp bởi máy chủ backend.

## Cách xem dữ liệu

1.  **Khởi động máy chủ backend**:
    ```bash
    cd backend
    npm install
    npm start
    ```

2.  Máy chủ sẽ chạy tại `http://localhost:3000`.

3.  Sử dụng trình duyệt hoặc một công cụ API (như Postman, Insomnia) để truy cập các endpoint sau và xem dữ liệu.

## Các Endpoint quan trọng

-   **Lấy danh sách đội xe**: `http://localhost:3000/api/master/fleet`
-   **Lấy danh sách các điểm thu gom**: `http://localhost:3000/api/points`
-   **Lấy vị trí phương tiện thời gian thực**: `http://localhost:3000/api/rt/vehicles`
-   **Lấy danh sách cảnh báo**: `http://localhost:3000/api/rt/alerts`
-   **Lấy danh sách các ngoại lệ**: `http://localhost:3000/api/exceptions`

**Lưu ý**: Dữ liệu được tạo ngẫu nhiên khi máy chủ khởi động hoặc trong quá trình chạy. Dữ liệu sẽ được đặt lại nếu máy chủ khởi động lại.
