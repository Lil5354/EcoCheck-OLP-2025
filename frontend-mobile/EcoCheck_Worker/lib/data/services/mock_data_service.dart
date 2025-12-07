/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import '../models/worker.dart';
import '../models/collection_request.dart';
import '../models/worker_route.dart';
import '../models/worker_statistics.dart';

class MockDataService {
  // Mock current worker
  static Worker getCurrentWorker() {
    return Worker(
      id: 'worker_001',
      userId: 'user_001',
      fullName: 'Nguyễn Văn An',
      email: 'worker@ecocheck.com',
      phoneNumber: '0901234567',
      avatar: null,
      vehicleType: 'Xe tải nhỏ',
      vehiclePlate: '51F-12345',
      status: 'active',
      teamId: 'team_001',
      teamName: 'Đội 1 - Quận 1',
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      updatedAt: DateTime.now(),
    );
  }

  // Mock worker statistics
  static WorkerStatistics getWorkerStatistics() {
    return WorkerStatistics(
      totalCollections: 145,
      completedCollections: 132,
      pendingCollections: 8,
      todayCollections: 12,
      totalWasteCollected: 2450.5,
      todayWasteCollected: 85.3,
      totalRoutes: 48,
      completedRoutes: 45,
      averageRating: 4.7,
    );
  }

  // Mock collection requests
  static List<CollectionRequest> getCollectionRequests() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      CollectionRequest(
        id: 'req_001',
        citizenId: 'citizen_001',
        citizenName: 'Trần Thị Bình',
        citizenPhone: '0912345678',
        address: '123 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM',
        latitude: 10.7769,
        longitude: 106.7009,
        wasteType: 'Rác hữu cơ',
        estimatedWeight: 5.0,
        description: 'Rác thải hữu cơ từ nhà hàng',
        images: null,
        status: 'assigned',
        priority: 'high',
        scheduledDate: today.add(const Duration(hours: 8)),
        assignedWorkerId: 'worker_001',
        assignedWorkerName: 'Nguyễn Văn An',
        routeId: 'route_001',
        collectedAt: null,
        actualWeight: null,
        collectionNotes: null,
        collectionImages: null,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      CollectionRequest(
        id: 'req_002',
        citizenId: 'citizen_002',
        citizenName: 'Lê Văn Cường',
        citizenPhone: '0923456789',
        address: '456 Lê Lợi, Phường Bến Thành, Quận 1, TP.HCM',
        latitude: 10.7722,
        longitude: 106.6989,
        wasteType: 'Nhựa',
        estimatedWeight: 3.5,
        description: 'Chai nhựa, túi nilon',
        images: null,
        status: 'in_progress',
        priority: 'medium',
        scheduledDate: today.add(const Duration(hours: 9)),
        assignedWorkerId: 'worker_001',
        assignedWorkerName: 'Nguyễn Văn An',
        routeId: 'route_001',
        collectedAt: null,
        actualWeight: null,
        collectionNotes: null,
        collectionImages: null,
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),
      CollectionRequest(
        id: 'req_003',
        citizenId: 'citizen_003',
        citizenName: 'Phạm Thị Dung',
        citizenPhone: '0934567890',
        address: '789 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM',
        latitude: 10.7794,
        longitude: 106.6950,
        wasteType: 'Giấy',
        estimatedWeight: 2.0,
        description: 'Giấy báo, hộp carton',
        images: null,
        status: 'assigned',
        priority: 'low',
        scheduledDate: today.add(const Duration(hours: 10)),
        assignedWorkerId: 'worker_001',
        assignedWorkerName: 'Nguyễn Văn An',
        routeId: 'route_001',
        collectedAt: null,
        actualWeight: null,
        collectionNotes: null,
        collectionImages: null,
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      CollectionRequest(
        id: 'req_004',
        citizenId: 'citizen_004',
        citizenName: 'Hoàng Minh Đức',
        citizenPhone: '0945678901',
        address: '321 Võ Văn Tần, Phường 6, Quận 3, TP.HCM',
        latitude: 10.7829,
        longitude: 106.6929,
        wasteType: 'Kim loại',
        estimatedWeight: 8.0,
        description: 'Lon nhôm, sắt vụn',
        images: null,
        status: 'completed',
        priority: 'medium',
        scheduledDate: today.add(const Duration(hours: 7)),
        assignedWorkerId: 'worker_001',
        assignedWorkerName: 'Nguyễn Văn An',
        routeId: 'route_001',
        collectedAt: today.add(const Duration(hours: 7, minutes: 30)),
        actualWeight: 7.5,
        collectionNotes: 'Đã thu gom đầy đủ',
        collectionImages: null,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: today.add(const Duration(hours: 7, minutes: 35)),
      ),
      CollectionRequest(
        id: 'req_005',
        citizenId: 'citizen_005',
        citizenName: 'Vũ Thị Hương',
        citizenPhone: '0956789012',
        address: '654 Điện Biên Phủ, Phường 22, Quận Bình Thạnh, TP.HCM',
        latitude: 10.8024,
        longitude: 106.7145,
        wasteType: 'Điện tử',
        estimatedWeight: 4.5,
        description: 'Linh kiện máy tính cũ',
        images: null,
        status: 'assigned',
        priority: 'urgent',
        scheduledDate: today.add(const Duration(hours: 11)),
        assignedWorkerId: 'worker_001',
        assignedWorkerName: 'Nguyễn Văn An',
        routeId: 'route_001',
        collectedAt: null,
        actualWeight: null,
        collectionNotes: null,
        collectionImages: null,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(minutes: 45)),
      ),
      CollectionRequest(
        id: 'req_006',
        citizenId: 'citizen_006',
        citizenName: 'Đỗ Văn Giang',
        citizenPhone: '0967890123',
        address: '147 Hai Bà Trưng, Phường Bến Nghé, Quận 1, TP.HCM',
        latitude: 10.7756,
        longitude: 106.7029,
        wasteType: 'Rác hữu cơ',
        estimatedWeight: 6.0,
        description: 'Rác thải từ chợ',
        images: null,
        status: 'pending',
        priority: 'high',
        scheduledDate: today.add(const Duration(hours: 14)),
        assignedWorkerId: null,
        assignedWorkerName: null,
        routeId: null,
        collectedAt: null,
        actualWeight: null,
        collectionNotes: null,
        collectionImages: null,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }

  // Mock worker routes
  static List<WorkerRoute> getWorkerRoutes() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      WorkerRoute(
        id: 'route_001',
        name: 'Tuyến Quận 1 - Sáng',
        workerId: 'worker_001',
        workerName: 'Nguyễn Văn An',
        vehiclePlate: '51F-12345',
        scheduledDate: today,
        status: 'in_progress',
        points: [
          RoutePoint(
            id: 'point_001',
            order: 1,
            collectionRequestId: 'req_004',
            address: '321 Võ Văn Tần, Phường 6, Quận 3, TP.HCM',
            latitude: 10.7829,
            longitude: 106.6929,
            wasteType: 'Kim loại',
            status: 'pending',
            arrivedAt: null,
            completedAt: null,
          ),
          RoutePoint(
            id: 'point_002',
            order: 2,
            collectionRequestId: 'req_001',
            address: '123 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM',
            latitude: 10.7769,
            longitude: 106.7009,
            wasteType: 'Rác hữu cơ',
            status: 'pending',
            arrivedAt: null,
            completedAt: null,
          ),
          RoutePoint(
            id: 'point_003',
            order: 3,
            collectionRequestId: 'req_002',
            address: '456 Lê Lợi, Phường Bến Thành, Quận 1, TP.HCM',
            latitude: 10.7722,
            longitude: 106.6989,
            wasteType: 'Nhựa',
            status: 'pending',
            arrivedAt: null,
            completedAt: null,
          ),
          RoutePoint(
            id: 'point_004',
            order: 4,
            collectionRequestId: 'req_003',
            address: '789 Pasteur, Phường Bến Nghé, Quận 1, TP.HCM',
            latitude: 10.7794,
            longitude: 106.6950,
            wasteType: 'Giấy',
            status: 'pending',
            arrivedAt: null,
            completedAt: null,
          ),
          RoutePoint(
            id: 'point_005',
            order: 5,
            collectionRequestId: 'req_005',
            address: '654 Điện Biên Phủ, Phường 22, Quận Bình Thạnh, TP.HCM',
            latitude: 10.8024,
            longitude: 106.7145,
            wasteType: 'Điện tử',
            status: 'pending',
            arrivedAt: null,
            completedAt: null,
          ),
        ],
        startedAt: today.add(const Duration(hours: 7)),
        completedAt: null,
        totalDistance: 15.3,
        totalCollections: 5,
        completedCollections: 0,
        createdAt: today.subtract(const Duration(days: 1)),
        updatedAt: today.add(const Duration(hours: 7)),
      ),
      WorkerRoute(
        id: 'route_002',
        name: 'Tuyến Quận 3 - Chiều',
        workerId: 'worker_001',
        workerName: 'Nguyễn Văn An',
        vehiclePlate: '51F-12345',
        scheduledDate: today.subtract(const Duration(days: 1)),
        status: 'completed',
        points: [
          RoutePoint(
            id: 'point_006',
            order: 1,
            collectionRequestId: 'req_old_001',
            address: '111 Cách Mạng Tháng 8, Quận 3, TP.HCM',
            latitude: 10.7865,
            longitude: 106.6818,
            wasteType: 'Rác hữu cơ',
            status: 'completed',
            arrivedAt: today.subtract(const Duration(days: 1, hours: -14)),
            completedAt: today.subtract(
              const Duration(days: 1, hours: -14, minutes: -15),
            ),
          ),
          RoutePoint(
            id: 'point_007',
            order: 2,
            collectionRequestId: 'req_old_002',
            address: '222 Lê Văn Sỹ, Quận 3, TP.HCM',
            latitude: 10.7898,
            longitude: 106.6756,
            wasteType: 'Nhựa',
            status: 'completed',
            arrivedAt: today.subtract(
              const Duration(days: 1, hours: -14, minutes: -30),
            ),
            completedAt: today.subtract(
              const Duration(days: 1, hours: -14, minutes: -45),
            ),
          ),
        ],
        startedAt: today.subtract(const Duration(days: 1, hours: -14)),
        completedAt: today.subtract(const Duration(days: 1, hours: -15)),
        totalDistance: 8.5,
        totalCollections: 2,
        completedCollections: 2,
        createdAt: today.subtract(const Duration(days: 2)),
        updatedAt: today.subtract(const Duration(days: 1, hours: -15)),
      ),
    ];
  }

  // Get today's collections
  static List<CollectionRequest> getTodayCollections() {
    return getCollectionRequests()
        .where(
          (req) =>
              req.assignedWorkerId == 'worker_001' &&
              req.status != 'pending' &&
              req.status != 'cancelled',
        )
        .toList();
  }

  // Get pending collections
  static List<CollectionRequest> getPendingCollections() {
    return getCollectionRequests()
        .where(
          (req) =>
              req.assignedWorkerId == 'worker_001' &&
              (req.status == 'assigned' || req.status == 'in_progress'),
        )
        .toList();
  }

  // Get completed collections
  static List<CollectionRequest> getCompletedCollections() {
    return getCollectionRequests()
        .where(
          (req) =>
              req.assignedWorkerId == 'worker_001' && req.status == 'completed',
        )
        .toList();
  }

  // Get active route
  static WorkerRoute? getActiveRoute() {
    return getWorkerRoutes()
        .where((route) => route.status == 'in_progress')
        .firstOrNull;
  }
}

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
