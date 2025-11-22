import '../models/collection_request.dart';
import '../services/mock_data_service.dart';

/// Repository cho Collection
class CollectionRepository {
  /// Lấy tất cả collection requests
  Future<List<CollectionRequest>> getAllCollections() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockDataService.getCollectionRequests();
  }

  /// Lấy collections hôm nay
  Future<List<CollectionRequest>> getTodayCollections() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockDataService.getTodayCollections();
  }

  /// Lấy pending collections
  Future<List<CollectionRequest>> getPendingCollections() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockDataService.getPendingCollections();
  }

  /// Lấy completed collections
  Future<List<CollectionRequest>> getCompletedCollections() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockDataService.getCompletedCollections();
  }

  /// Cập nhật trạng thái collection
  Future<CollectionRequest> updateCollectionStatus({
    required String requestId,
    required String status,
    double? actualWeight,
    String? notes,
    List<String>? images,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Real API call
    // final response = await api.patch('/collections/$requestId', data: {...});

    final collections = MockDataService.getCollectionRequests();
    final collection = collections.firstWhere((c) => c.id == requestId);

    return collection.copyWith(
      status: status,
      collectedAt: status == 'collected'
          ? DateTime.now()
          : collection.collectedAt,
      actualWeight: actualWeight,
      collectionNotes: notes,
      collectionImages: images,
    );
  }
}
