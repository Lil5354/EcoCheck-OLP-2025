# Contributing to EcoCheck

Cảm ơn bạn đã quan tâm đến việc đóng góp cho EcoCheck! Tài liệu này cung cấp hướng dẫn về cách đóng góp vào dự án.

## Code of Conduct

Dự án này tuân thủ Code of Conduct. Bằng cách tham gia, bạn được kỳ vọng sẽ duy trì tiêu chuẩn này.

## How Can I Contribute?

### Reporting Bugs

Trước khi tạo bug report:
- Kiểm tra xem bug đã được báo cáo chưa trong [Issues](https://github.com/Lil5354/EcoCheck-OLP-2025/issues)
- Đảm bảo bạn đang sử dụng phiên bản mới nhất

Khi tạo bug report, vui lòng bao gồm:
- Mô tả rõ ràng về bug
- Các bước để reproduce
- Hành vi mong đợi
- Hành vi thực tế
- Screenshots (nếu có)
- Môi trường (OS, Node.js version, Docker version, etc.)

### Suggesting Enhancements

Enhancement suggestions được chào đón! Vui lòng:
- Kiểm tra xem enhancement đã được đề xuất chưa
- Cung cấp mô tả chi tiết về enhancement
- Giải thích lý do tại sao enhancement này hữu ích
- Đề xuất cách triển khai (nếu có)

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make your changes**
   - Tuân thủ code style hiện tại
   - Thêm comments cho code phức tạp
   - Cập nhật documentation nếu cần

4. **Commit your changes**
   ```bash
   git commit -m "Add amazing feature"
   ```
   - Sử dụng commit messages rõ ràng và mô tả
   - Reference issue numbers nếu có

5. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```

6. **Open a Pull Request**
   - Mô tả rõ ràng về những thay đổi
   - Reference related issues
   - Đảm bảo tất cả tests pass (nếu có)

## Development Setup

### Prerequisites

- Node.js 18+ và npm
- Docker và Docker Compose
- Git
- (Optional) Flutter SDK cho mobile development

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/Lil5354/EcoCheck-OLP-2025.git
   cd EcoCheck-OLP-2025
   ```

2. **Start services with Docker**
   ```bash
   # Windows
   .\setup.ps1
   
   # Linux/Mac
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Development mode**
   ```bash
   # Backend
   cd backend
   npm install
   npm run dev
   
   # Frontend Web
   cd frontend-web-manager
   npm install
   npm run dev
   
   # Mobile (Flutter)
   cd frontend-mobile/EcoCheck_Worker  # hoặc EcoCheck_User
   flutter pub get
   flutter run
   ```

## Code Style

### JavaScript/Node.js (Backend)

- Sử dụng ESLint configuration có sẵn
- 2 spaces cho indentation
- Sử dụng `const` và `let`, tránh `var`
- Sử dụng async/await thay vì callbacks
- Thêm JSDoc comments cho functions phức tạp

### React (Frontend Web)

- Sử dụng functional components với hooks
- Component names sử dụng PascalCase
- File names sử dụng PascalCase cho components
- Props destructuring khi có thể
- Sử dụng meaningful variable names

### Dart/Flutter (Frontend Mobile)

- Tuân thủ [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Sử dụng `dart format` để format code
- Sử dụng meaningful variable names
- Thêm comments cho complex logic

### SQL (Database)

- Sử dụng UPPERCASE cho SQL keywords
- Indentation rõ ràng
- Thêm comments cho complex queries
- Sử dụng meaningful table và column names

## Project Structure

```
EcoCheck-OLP-2025/
├── backend/          # Node.js backend API
├── frontend-web-manager/  # React web application
├── frontend-mobile/  # Flutter mobile apps
├── db/              # Database migrations và scripts
├── docs/            # Documentation
├── scripts/         # Utility scripts
└── docker-compose.yml
```

## Testing

- Chạy tests trước khi commit (khi có tests)
- Đảm bảo không có linter errors
- Test trên multiple platforms nếu có thể

## Documentation

- Cập nhật README.md nếu thay đổi setup process
- Cập nhật API documentation nếu thay đổi endpoints
- Thêm comments cho code phức tạp
- Cập nhật CHANGELOG.md cho significant changes

## License

Bằng cách đóng góp, bạn đồng ý rằng các đóng góp của bạn sẽ được cấp phép dưới MIT License.

## Questions?

Nếu bạn có câu hỏi, vui lòng:
- Tạo một [Issue](https://github.com/Lil5354/EcoCheck-OLP-2025/issues)
- Kiểm tra [README.md](README.md) để biết thêm thông tin

Cảm ơn bạn đã đóng góp! 🎉

