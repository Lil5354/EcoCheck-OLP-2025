class WorkerRoute {
  final String id;
  final String name;
  final String workerId;
  final String workerName;
  final String? vehiclePlate;
  final DateTime scheduledDate;
  final String status; // pending, in_progress, completed, cancelled
  final List<RoutePoint> points;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double? totalDistance;
  final int? totalCollections;
  final int? completedCollections;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Depot (Start point)
  final String? depotId;
  final String? depotName;
  final double? depotLat;
  final double? depotLon;

  // Dump (End point)
  final String? dumpId;
  final String? dumpName;
  final double? dumpLat;
  final double? dumpLon;

  WorkerRoute({
    required this.id,
    required this.name,
    required this.workerId,
    required this.workerName,
    this.vehiclePlate,
    required this.scheduledDate,
    required this.status,
    required this.points,
    this.startedAt,
    this.completedAt,
    this.totalDistance,
    this.totalCollections,
    this.completedCollections,
    required this.createdAt,
    this.updatedAt,
    this.depotId,
    this.depotName,
    this.depotLat,
    this.depotLon,
    this.dumpId,
    this.dumpName,
    this.dumpLat,
    this.dumpLon,
  });

  factory WorkerRoute.fromJson(Map<String, dynamic> json) {
    // API có thể trả về 'points' hoặc 'stops' tùy endpoint
    final pointsData = json['points'] ?? json['stops'] ?? [];

    return WorkerRoute(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Lộ trình không tên',
      workerId: json['worker_id']?.toString() ?? '',
      workerName: json['worker_name']?.toString() ?? 'Unknown',
      vehiclePlate: json['vehicle_plate']?.toString(),
      scheduledDate: _parseScheduledDate(
        json['scheduled_date']?.toString() ??
            json['schedule_date']?.toString() ??
            DateTime.now().toIso8601String(),
      ),
      status: json['status']?.toString() ?? 'planned',
      points: (pointsData as List)
          .map((point) => RoutePoint.fromJson(point as Map<String, dynamic>))
          .toList(),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      totalDistance: json['total_distance'] != null
          ? double.tryParse(json['total_distance'].toString())
          : null,
      totalCollections: json['total_collections'] != null
          ? int.tryParse(json['total_collections'].toString())
          : (json['total_stops'] != null
                ? int.tryParse(json['total_stops'].toString())
                : null),
      completedCollections: json['completed_collections'] != null
          ? int.tryParse(json['completed_collections'].toString())
          : (json['completed_stops'] != null
                ? int.tryParse(json['completed_stops'].toString())
                : null),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      // Depot info
      depotId: json['depot_id'] as String?,
      depotName: json['depot_name'] as String?,
      depotLat: json['depot_lat'] != null
          ? double.tryParse(json['depot_lat'].toString())
          : null,
      depotLon: json['depot_lon'] != null
          ? double.tryParse(json['depot_lon'].toString())
          : null,
      // Dump info
      dumpId: json['dump_id'] as String?,
      dumpName: json['dump_name'] as String?,
      dumpLat: json['dump_lat'] != null
          ? double.tryParse(json['dump_lat'].toString())
          : null,
      dumpLon: json['dump_lon'] != null
          ? double.tryParse(json['dump_lon'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'worker_id': workerId,
      'worker_name': workerName,
      'vehicle_plate': vehiclePlate,
      'schedule_date': scheduledDate.toIso8601String(),
      'status': status,
      'points': points.map((point) => point.toJson()).toList(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'total_distance': totalDistance,
      'total_collections': totalCollections,
      'completed_collections': completedCollections,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Parse scheduled_date as local date (ignore timezone)
  // Backend sends "2025-12-03T00:00:00.000Z" but we want date "2025-12-03" in local timezone
  static DateTime _parseScheduledDate(String dateStr) {
    try {
      // Extract date portion only (YYYY-MM-DD)
      final datePart = dateStr.split('T')[0];
      final parts = datePart.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        // Create local date at midnight
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Silently fail - fallback to current date
    }
    return DateTime.now();
  }

  /// Xác định ca làm việc dựa trên thời gian bắt đầu của route
  /// Morning: 6:00 - 11:59
  /// Afternoon: 12:00 - 17:59
  /// Evening: 18:00 - 5:59
  String getShift() {
    // Nếu có startedAt, dùng thời gian thực tế
    final time = startedAt ?? scheduledDate;
    final hour = time.hour;

    if (hour >= 6 && hour < 12) {
      return 'morning';
    } else if (hour >= 12 && hour < 18) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }

  /// Lấy tên ca làm việc tiếng Việt
  String getShiftName() {
    switch (getShift()) {
      case 'morning':
        return 'Ca Sáng';
      case 'afternoon':
        return 'Ca Chiều';
      case 'evening':
        return 'Ca Tối';
      default:
        return 'Không xác định';
    }
  }

  /// Lấy khung giờ ca làm việc
  String getShiftTimeRange() {
    switch (getShift()) {
      case 'morning':
        return '6:00 - 11:59';
      case 'afternoon':
        return '12:00 - 17:59';
      case 'evening':
        return '18:00 - 5:59';
      default:
        return '';
    }
  }

  /// Kiểm tra xem route có đúng ca làm việc không
  /// Dựa trên thời gian bắt đầu (startedAt hoặc scheduledDate)
  bool isCorrectShift(String expectedShift) {
    return getShift() == expectedShift;
  }

  /// Lấy thông tin chi tiết về ca làm việc
  Map<String, dynamic> getShiftInfo() {
    final shift = getShift();
    final time = startedAt ?? scheduledDate;

    return {
      'shift': shift,
      'shift_name': getShiftName(),
      'time_range': getShiftTimeRange(),
      'actual_time':
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'is_valid': _isTimeInShiftRange(time.hour, shift),
    };
  }

  /// Kiểm tra xem giờ có nằm trong khung giờ ca không
  bool _isTimeInShiftRange(int hour, String shift) {
    switch (shift) {
      case 'morning':
        return hour >= 6 && hour < 12;
      case 'afternoon':
        return hour >= 12 && hour < 18;
      case 'evening':
        return hour >= 18 || hour < 6;
      default:
        return false;
    }
  }
}

class RoutePoint {
  final String id;
  final int order;
  final String? collectionRequestId;
  final String? routeId;
  final String? pointId;
  final String address;
  final double latitude;
  final double longitude;
  final String? wasteType;
  final String status; // pending, completed, skipped, collected
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final double? actualWeightKg;
  final List<String>? photoUrls;
  final String? notes;
  final String? reason;

  RoutePoint({
    required this.id,
    required this.order,
    this.collectionRequestId,
    this.routeId,
    this.pointId,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.wasteType,
    required this.status,
    this.arrivedAt,
    this.completedAt,
    this.actualWeightKg,
    this.photoUrls,
    this.notes,
    this.reason,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    // API trả về stop_order hoặc order, lat/lon hoặc latitude/longitude
    final orderValue = json['stop_order'] ?? json['seq'] ?? json['order'] ?? 0;
    final lat = json['lat'] ?? json['latitude'] ?? 0.0;
    final lon = json['lon'] ?? json['longitude'] ?? 0.0;
    final addr = json['address'] ?? json['point_address'] ?? 'Điểm thu gom';

    // Parse photo_urls as List<String>
    List<String>? photoUrls;
    if (json['photo_urls'] != null) {
      final urls = json['photo_urls'];
      if (urls is List) {
        photoUrls = urls.map((e) => e.toString()).toList();
      }
    }

    return RoutePoint(
      id: json['id'] as String,
      order: orderValue is int
          ? orderValue
          : int.tryParse(orderValue.toString()) ?? 0,
      collectionRequestId: json['collection_request_id'] as String?,
      routeId: json['route_id'] as String?,
      pointId: json['point_id'] as String?,
      address: addr,
      latitude: lat is num
          ? lat.toDouble()
          : double.tryParse(lat.toString()) ?? 0.0,
      longitude: lon is num
          ? lon.toDouble()
          : double.tryParse(lon.toString()) ?? 0.0,
      wasteType: json['waste_type'] as String?,
      status: json['status'] as String? ?? 'pending',
      arrivedAt: json['arrived_at'] ?? json['actual_at'] != null
          ? DateTime.parse((json['arrived_at'] ?? json['actual_at']) as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      actualWeightKg: json['actual_weight_kg'] != null
          ? double.tryParse(json['actual_weight_kg'].toString())
          : null,
      photoUrls: photoUrls,
      notes: json['notes'] as String?,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'collection_request_id': collectionRequestId,
      'route_id': routeId,
      'point_id': pointId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'waste_type': wasteType,
      'status': status,
      'arrived_at': arrivedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'actual_weight_kg': actualWeightKg,
      'photo_urls': photoUrls,
      'notes': notes,
      'reason': reason,
    };
  }
}
