# 📱 HƯỚNG DẪN CHO MOBILE DEVELOPER

## 🎯 MỤC ĐÍCH

Tài liệu này hướng dẫn mobile developer bổ sung code để liên kết với backend web, đảm bảo các chức năng hoạt động đầy đủ.

---

## ⚙️ SETUP SERVER

### 1. Khởi động Docker Services

```bash
# Khởi động tất cả services (PostgreSQL, Redis, Orion-LD, MongoDB)
docker compose up -d

# Kiểm tra services đang chạy
docker compose ps
```

### 2. Khởi động Backend

```bash
cd backend
npm install  # Cài đặt dependencies (nếu chưa có)
npm run dev  # Chạy backend trên port 3000
```

**Lưu ý:** Backend chạy tại `http://localhost:3000` (hoặc `http://10.0.2.2:3000` cho Android emulator)

### 3. Khởi động Frontend Web (Optional - để test)

```bash
cd frontend-web-manager
npm install
npm run dev  # Chạy trên port 5173
```

### 4. Kiểm tra kết nối

- Backend health: `http://localhost:3000/health`
- API status: `http://localhost:3000/api/status`

---

## 📋 CÁC PHẦN CODE CẦN BỔ SUNG

### ✅ BÀI TOÁN 1: Real-time Update khi gán nhân viên (OPTIONAL)

**Mục đích:** Worker nhận thông báo real-time khi được gán schedule mới.

#### Cần làm:

1. **Tạo Socket.IO Service**

File: `frontend-mobile/EcoCheck_Worker/lib/core/network/socket_service.dart`

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class SocketService {
  IO.Socket? _socket;
  String? _employeeId;

  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    _employeeId = prefs.getString('worker_id');

    if (_employeeId == null) {
      print('⚠️ Worker ID not found, cannot connect to Socket.IO');
      return;
    }

    try {
      _socket = IO.io(
        ApiConstants.devBaseUrl.replaceFirst('http://', 'ws://'),
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
      );

      // Join worker room
      _socket!.onConnect((_) {
        print('✅ Socket.IO connected');
        _socket!.emit('join', {'room': 'worker:$_employeeId'});
      });

      // Listen for schedule assigned
      _socket!.on('schedule:assigned', (data) {
        print('📋 Schedule assigned: $data');
        // Emit event hoặc callback để UI refresh
      });

      _socket!.onDisconnect((_) {
        print('❌ Socket.IO disconnected');
      });

      _socket!.onError((error) {
        print('❌ Socket.IO error: $error');
      });
    } catch (e) {
      print('❌ Failed to connect Socket.IO: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  // Listen to specific event
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  // Emit event
  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }
}
```

2. **Tích hợp vào CollectionsScreen**

File: `frontend-mobile/EcoCheck_Worker/lib/presentation/screens/collections_screen.dart`

```dart
import '../../core/network/socket_service.dart';

class _CollectionsScreenState extends State<CollectionsScreen> {
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _socketService.connect();
    _socketService.on('schedule:assigned', (data) {
      // Refresh collections list
      context.read<CollectionBloc>().add(LoadCollections());
    });
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}
```

---

### ✅ BÀI TOÁN 2: Hiển thị Routes đã tối ưu (QUAN TRỌNG)

**Mục đích:** Worker xem và thực hiện routes đã được tối ưu từ web manager.

#### Cần làm:

1. **Sửa RouteRepository để parse geojson**

File: `frontend-mobile/EcoCheck_Worker/lib/data/repositories/route_repository.dart`

```dart
/// Lấy active route từ backend
Future<WorkerRoute?> getActiveRoute() async {
  if (_employeeId == null) {
    throw Exception('Worker ID not found. Please login again.');
  }

  try {
    final response = await _apiClient.get(
      ApiConstants.activeRouteEndpoint,
      queryParams: {'employee_id': _employeeId!},
    );

    if (response['ok'] == true) {
      final data = response['data'];
      if (data == null) {
        return null; // No active route
      }

      // Parse geojson từ meta hoặc data
      Map<String, dynamic>? geojson;
      if (data['meta'] != null && data['meta']['geojson'] != null) {
        geojson = data['meta']['geojson'];
      } else if (data['geojson'] != null) {
        geojson = data['geojson'];
      }

      // Parse stops
      List<RoutePoint> points = [];
      if (data['stops'] != null && data['stops'] is List) {
        points = (data['stops'] as List).map((stop) {
          return RoutePoint(
            id: stop['point_id'] ?? stop['id'] ?? '',
            order: stop['seq'] ?? 0,
            collectionRequestId: stop['schedule_id'],
            address: stop['address'] ?? '',
            latitude: stop['lat']?.toDouble() ?? 0.0,
            longitude: stop['lon']?.toDouble() ?? 0.0,
            wasteType: stop['waste_type'] ?? 'household',
            status: stop['status'] ?? 'pending',
            arrivedAt: stop['arrived_at'] != null 
              ? DateTime.parse(stop['arrived_at']) 
              : null,
            completedAt: stop['completed_at'] != null 
              ? DateTime.parse(stop['completed_at']) 
              : null,
          );
        }).toList();
      }

      return WorkerRoute(
        id: data['id'] ?? '',
        name: data['name'] ?? 'Route ${data['id']}',
        workerId: _employeeId!,
        workerName: data['worker_name'] ?? '',
        vehiclePlate: data['vehicle_plate'] ?? data['vehiclePlate'] ?? '',
        scheduleDate: data['start_at'] != null 
          ? DateTime.parse(data['start_at']) 
          : DateTime.now(),
        status: data['status'] ?? 'pending',
        points: points,
        startedAt: data['started_at'] != null 
          ? DateTime.parse(data['started_at']) 
          : null,
        completedAt: data['completed_at'] != null 
          ? DateTime.parse(data['completed_at']) 
          : null,
        totalDistance: data['distance']?.toDouble() ?? 0.0,
        totalCollections: points.length,
        completedCollections: points.where((p) => p.status == 'completed').length,
        createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
        updatedAt: data['updated_at'] != null 
          ? DateTime.parse(data['updated_at']) 
          : DateTime.now(),
        geojson: geojson, // Thêm field này vào WorkerRoute model
      );
    } else {
      throw Exception(response['error'] ?? 'Failed to get active route');
    }
  } catch (e) {
    print('Error getting active route: $e');
    return null;
  }
}
```

2. **Cập nhật WorkerRoute Model**

File: `frontend-mobile/EcoCheck_Worker/lib/data/models/worker_route.dart`

```dart
class WorkerRoute {
  // ... existing fields ...
  final Map<String, dynamic>? geojson; // Thêm field này

  WorkerRoute({
    // ... existing parameters ...
    this.geojson,
  });

  // Update fromJson và toJson để include geojson
  factory WorkerRoute.fromJson(Map<String, dynamic> json) {
    return WorkerRoute(
      // ... existing fields ...
      geojson: json['geojson'],
    );
  }
}
```

3. **Hiển thị Route trên Map**

File: `frontend-mobile/EcoCheck_Worker/lib/presentation/widgets/route/route_map_view.dart`

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteMapView extends StatefulWidget {
  final WorkerRoute route;

  const RouteMapView({required this.route});

  @override
  State<RouteMapView> createState() => _RouteMapViewState();
}

class _RouteMapViewState extends State<RouteMapView> {
  GoogleMapController? _mapController;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _parseGeojson();
  }

  void _parseGeojson() {
    if (widget.route.geojson == null) return;

    try {
      // Parse GeoJSON LineString
      final features = widget.route.geojson!['features'] as List?;
      if (features != null && features.isNotEmpty) {
        final geometry = features[0]['geometry'];
        if (geometry['type'] == 'LineString') {
          final coordinates = geometry['coordinates'] as List;
          _routePoints = coordinates.map((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        }
      }
    } catch (e) {
      print('Error parsing geojson: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _routePoints.isNotEmpty 
          ? _routePoints.first 
          : LatLng(10.78, 106.7),
        zoom: 13,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _drawRoute();
      },
      polylines: {
        Polyline(
          polylineId: PolylineId('route'),
          points: _routePoints,
          color: Colors.blue,
          width: 4,
        ),
      },
      markers: _buildMarkers(),
    );
  }

  void _drawRoute() {
    if (_routePoints.isEmpty) return;
    
    // Fit bounds to show entire route
    final bounds = _calculateBounds(_routePoints);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;
    
    for (var point in points) {
      minLat = minLat == null ? point.latitude : min(minLat, point.latitude);
      maxLat = maxLat == null ? point.latitude : max(maxLat, point.latitude);
      minLng = minLng == null ? point.longitude : min(minLng, point.longitude);
      maxLng = maxLng == null ? point.longitude : max(maxLng, point.longitude);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    // Depot marker (start)
    if (widget.route.points.isNotEmpty) {
      final firstPoint = widget.route.points.first;
      markers.add(Marker(
        markerId: MarkerId('depot'),
        position: LatLng(firstPoint.latitude, firstPoint.longitude),
        infoWindow: InfoWindow(title: 'Điểm bắt đầu'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    
    // Stop markers (numbered)
    for (var i = 0; i < widget.route.points.length; i++) {
      final point = widget.route.points[i];
      markers.add(Marker(
        markerId: MarkerId('stop_$i'),
        position: LatLng(point.latitude, point.longitude),
        infoWindow: InfoWindow(
          title: 'Điểm ${i + 1}',
          snippet: point.address,
        ),
      ));
    }
    
    return markers;
  }
}
```

---

### ✅ BÀI TOÁN 3: Nhận Route từ Điều phối động

**Mục đích:** Worker nhận route mới khi có alert được xử lý.

#### Cần làm:

1. **Tích hợp Socket.IO để listen route:assigned**

File: `frontend-mobile/EcoCheck_Worker/lib/core/network/socket_service.dart`

Thêm vào `connect()` method:

```dart
// Listen for route assigned
_socket!.on('route:assigned', (data) {
  print('🚛 Route assigned: $data');
  // Emit event hoặc callback để UI refresh routes
  // Có thể show notification
});
```

2. **Refresh Routes khi nhận event**

File: `frontend-mobile/EcoCheck_Worker/lib/presentation/screens/routes_screen.dart`

```dart
@override
void initState() {
  super.initState();
  _socketService.connect();
  _socketService.on('route:assigned', (data) {
    // Refresh routes list
    context.read<RouteBloc>().add(LoadRoutes());
    
    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Có tuyến đường mới được gán'),
        action: SnackBarAction(
          label: 'Xem',
          onPressed: () {
            // Navigate to route detail
          },
        ),
      ),
    );
  });
}
```

---

### ✅ BÀI TOÁN 5: Tạo và nhận thông báo Exception

**Mục đích:** Worker có thể báo cáo exception và nhận phản hồi.

#### Cần làm:

1. **Tạo ExceptionRepository**

File: `frontend-mobile/EcoCheck_Worker/lib/data/repositories/exception_repository.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../../core/constants/api_constants.dart';

class ExceptionRepository {
  final SharedPreferences _prefs;
  final ApiClient _apiClient = ApiClient();

  ExceptionRepository(this._prefs);

  String? get _employeeId => _prefs.getString('worker_id');

  /// Tạo exception mới
  Future<Map<String, dynamic>> createException({
    required String routeId,
    String? stopId,
    required String type,
    required String reason,
    String? photoUrl,
  }) async {
    if (_employeeId == null) {
      throw Exception('Worker ID not found. Please login again.');
    }

    try {
      final response = await _apiClient.post(
        '${ApiConstants.apiPrefix}/exceptions',
        {
          'route_id': routeId,
          'stop_id': stopId,
          'type': type,
          'reason': reason,
          'photo_url': photoUrl,
          'employee_id': _employeeId,
        },
      );

      if (response['ok'] == true) {
        return response['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response['error'] ?? 'Failed to create exception');
      }
    } catch (e) {
      print('Error creating exception: $e');
      throw Exception('Failed to create exception: ${e.toString()}');
    }
  }

  /// Lấy exceptions của worker
  Future<List<Map<String, dynamic>>> getMyExceptions() async {
    if (_employeeId == null) {
      throw Exception('Worker ID not found. Please login again.');
    }

    try {
      final response = await _apiClient.get(
        '${ApiConstants.apiPrefix}/exceptions',
        queryParams: {'employee_id': _employeeId!},
      );

      if (response['ok'] == true) {
        return List<Map<String, dynamic>>.from(response['data'] ?? []);
      } else {
        throw Exception(response['error'] ?? 'Failed to get exceptions');
      }
    } catch (e) {
      print('Error getting exceptions: $e');
      return [];
    }
  }
}
```

2. **Tạo UI Form Exception**

File: `frontend-mobile/EcoCheck_Worker/lib/presentation/widgets/exception/create_exception_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../data/repositories/exception_repository.dart';
import '../../../data/services/image_upload_service.dart';

class CreateExceptionDialog extends StatefulWidget {
  final String routeId;
  final String? stopId;

  const CreateExceptionDialog({
    required this.routeId,
    this.stopId,
  });

  @override
  State<CreateExceptionDialog> createState() => _CreateExceptionDialogState();
}

class _CreateExceptionDialogState extends State<CreateExceptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _selectedType;
  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _exceptionTypes = [
    'vehicle_breakdown',
    'wrong_waste_type',
    'road_blocked',
    'cannot_collect',
    'other',
  ];

  final Map<String, String> _typeLabels = {
    'vehicle_breakdown': 'Xe hỏng',
    'wrong_waste_type': 'Sai loại rác',
    'road_blocked': 'Đường bị chặn',
    'cannot_collect': 'Không thể thu gom',
    'other': 'Khác',
  };

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final exceptionRepo = ExceptionRepository(
        await SharedPreferences.getInstance(),
      );
      final imageUploadService = ImageUploadService();

      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await imageUploadService.uploadImage(_selectedImage!);
      }

      await exceptionRepo.createException(
        routeId: widget.routeId,
        stopId: widget.stopId,
        type: _selectedType!,
        reason: _reasonController.text,
        photoUrl: photoUrl,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã gửi báo cáo ngoại lệ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Báo cáo ngoại lệ'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Type dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(labelText: 'Loại ngoại lệ'),
                items: _exceptionTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_typeLabels[type] ?? type),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (value) => 
                  value == null ? 'Vui lòng chọn loại ngoại lệ' : null,
              ),
              SizedBox(height: 16),
              
              // Reason text field
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(labelText: 'Lý do'),
                maxLines: 3,
                validator: (value) => 
                  value?.isEmpty ?? true ? 'Vui lòng nhập lý do' : null,
              ),
              SizedBox(height: 16),
              
              // Image picker
              if (_selectedImage != null)
                Image.file(_selectedImage!, height: 100),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.camera_alt),
                label: Text('Chụp ảnh'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading 
            ? CircularProgressIndicator() 
            : Text('Gửi'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
```

3. **Listen Socket.IO events cho Exception**

File: `frontend-mobile/EcoCheck_Worker/lib/core/network/socket_service.dart`

Thêm vào `connect()` method:

```dart
// Listen for exception approved
_socket!.on('exception:approved', (data) {
  print('✅ Exception approved: $data');
  // Show notification
});

// Listen for exception rejected
_socket!.on('exception:rejected', (data) {
  print('❌ Exception rejected: $data');
  // Show notification
});
```

---

## 📦 DEPENDENCIES CẦN THÊM

File: `frontend-mobile/EcoCheck_Worker/pubspec.yaml`

```yaml
dependencies:
  # ... existing dependencies ...
  socket_io_client: ^2.0.3+1  # Cho Socket.IO real-time communication
```

Sau đó chạy:
```bash
flutter pub get
```

---

## 🔧 CẤU HÌNH API CONSTANTS

File: `frontend-mobile/EcoCheck_Worker/lib/core/constants/api_constants.dart`

Đảm bảo có các endpoints sau:

```dart
// Route Endpoints
static const String activeRoute = '$apiPrefix/routes/active';
static String startRoute(String id) => '$apiPrefix/routes/$id/start';
static String completeRoute(String id) => '$apiPrefix/routes/$id/complete';

// Exception Endpoints
static const String exceptions = '$apiPrefix/exceptions';
```

---

## 🧪 TESTING

### 1. Test Routes Active

```dart
// Trong RoutesScreen, gọi:
final route = await routeRepository.getActiveRoute();
if (route != null) {
  print('Route ID: ${route.id}');
  print('Stops: ${route.points.length}');
  print('Has geojson: ${route.geojson != null}');
}
```

### 2. Test Socket.IO Connection

```dart
final socketService = SocketService();
await socketService.connect();
// Kiểm tra console log xem có "Socket.IO connected" không
```

### 3. Test Exception Creation

```dart
final exceptionRepo = ExceptionRepository(prefs);
await exceptionRepo.createException(
  routeId: 'test-route-id',
  type: 'vehicle_breakdown',
  reason: 'Test exception',
);
```

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **Backend phải chạy trước:** Đảm bảo backend đang chạy trên port 3000 trước khi test mobile app.

2. **Android Emulator:** Sử dụng `http://10.0.2.2:3000` thay vì `localhost:3000`.

3. **iOS Simulator:** Có thể dùng `http://localhost:3000`.

4. **Real Device:** Cần thay `localhost` bằng IP máy tính (ví dụ: `http://192.168.1.100:3000`).

5. **Socket.IO URL:** Phải dùng `ws://` hoặc `wss://` protocol, không dùng `http://`.

6. **Error Handling:** Luôn wrap API calls trong try-catch và hiển thị error message cho user.

7. **Loading States:** Hiển thị loading indicator khi đang fetch data.

8. **Offline Support:** Cân nhắc cache data để app hoạt động khi mất kết nối.

---

## 📞 LIÊN HỆ

Nếu có vấn đề hoặc câu hỏi, vui lòng liên hệ team backend hoặc xem documentation trong folder `docs/`.

---

## ✅ CHECKLIST HOÀN THÀNH

- [ ] Cài đặt `socket_io_client` package
- [ ] Tạo SocketService và kết nối với backend
- [ ] Sửa RouteRepository để parse geojson
- [ ] Cập nhật WorkerRoute model với geojson field
- [ ] Hiển thị route trên map với geojson
- [ ] Listen event `route:assigned` và refresh routes
- [ ] Tạo ExceptionRepository
- [ ] Tạo UI form để worker tạo exception
- [ ] Listen events `exception:approved` và `exception:rejected`
- [ ] (Optional) Listen event `schedule:assigned`
- [ ] Test tất cả các chức năng
- [ ] Xử lý error cases và edge cases

---

**Chúc bạn code vui vẻ! 🚀**

