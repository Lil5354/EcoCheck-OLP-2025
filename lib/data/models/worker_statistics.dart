class WorkerStatistics {
  final int totalCollections;
  final int completedCollections;
  final int pendingCollections;
  final int todayCollections;
  final double totalWasteCollected; // in kg
  final double todayWasteCollected;
  final int totalRoutes;
  final int completedRoutes;
  final double averageRating;

  WorkerStatistics({
    required this.totalCollections,
    required this.completedCollections,
    required this.pendingCollections,
    required this.todayCollections,
    required this.totalWasteCollected,
    required this.todayWasteCollected,
    required this.totalRoutes,
    required this.completedRoutes,
    required this.averageRating,
  });

  factory WorkerStatistics.fromJson(Map<String, dynamic> json) {
    return WorkerStatistics(
      totalCollections: json['total_collections'] as int,
      completedCollections: json['completed_collections'] as int,
      pendingCollections: json['pending_collections'] as int,
      todayCollections: json['today_collections'] as int,
      totalWasteCollected: (json['total_waste_collected'] as num).toDouble(),
      todayWasteCollected: (json['today_waste_collected'] as num).toDouble(),
      totalRoutes: json['total_routes'] as int,
      completedRoutes: json['completed_routes'] as int,
      averageRating: (json['average_rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_collections': totalCollections,
      'completed_collections': completedCollections,
      'pending_collections': pendingCollections,
      'today_collections': todayCollections,
      'total_waste_collected': totalWasteCollected,
      'today_waste_collected': todayWasteCollected,
      'total_routes': totalRoutes,
      'completed_routes': completedRoutes,
      'average_rating': averageRating,
    };
  }
}
