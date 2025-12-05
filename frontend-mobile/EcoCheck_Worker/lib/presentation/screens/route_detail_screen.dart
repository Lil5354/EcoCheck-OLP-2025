/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/socket_service.dart';
import '../../data/models/worker_route.dart';
import '../../data/services/location_service.dart';
import '../blocs/route/route_bloc.dart';
import '../blocs/route/route_event.dart';
import '../blocs/route/route_state.dart';
import '../widgets/route/route_map_view.dart';
import '../widgets/route/task_list_view.dart';
import '../widgets/route/complete_task_dialog.dart';
import '../widgets/route/route_completion_dialog.dart';
import '../widgets/route/shift_indicator.dart';

/// Route Detail Screen - ĐÃ TÁCH LOGIC RA CÁC FILE NHỎ
///
/// Structure:
/// - RouteMapView: OpenStreetMap (route_map_view.dart)
/// - TaskListView: Task sidebar (task_list_view.dart)
/// - RouteInfoCard: Route info header (route_info_card.dart)
/// - CompleteTaskDialog: Complete dialog (complete_task_dialog.dart)
/// - LocationService: GPS & Navigation (location_service.dart)
class RouteDetailScreen extends StatefulWidget {
  final WorkerRoute route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  MapController? _mapController;
  int? _selectedPointIndex;
  final Map<String, List<XFile>> _taskImages = {};
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _cleanupRealtimeListeners();
    super.dispose();
  }

  /// Setup realtime Socket.IO listeners
  void _setupRealtimeListeners() {
    // Listen for route stop completion from other sources (e.g., manager updates)
    _socketService.onRouteStopCompleted((data) {
      if (mounted && data['route_id'] == widget.route.id) {
        print('🔄 Route stop completed via socket: $data');
        // Reload route data để cập nhật UI realtime
        context.read<RouteBloc>().add(
          LoadRoutesRequested(personnelId: widget.route.workerId),
        );

        // Force rebuild để cập nhật map và markers
        if (mounted) {
          setState(() {});
        }
      }
    });

    // Listen for route started
    _socketService.onRouteStarted((data) {
      if (mounted && data['route_id'] == widget.route.id) {
        print('🚀 Route started via socket: $data');
        context.read<RouteBloc>().add(
          LoadRoutesRequested(personnelId: widget.route.workerId),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚀 Đã bắt đầu lộ trình!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });

    // Listen for route completion
    _socketService.onRouteCompleted((data) {
      if (mounted && data['route_id'] == widget.route.id) {
        print('✅ Route completed via socket: $data');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Lộ trình đã được hoàn thành!'),
            backgroundColor: AppColors.completed,
          ),
        );

        // Reload routes list
        context.read<RouteBloc>().add(
          LoadRoutesRequested(personnelId: widget.route.workerId),
        );

        // Pop về màn hình chính
        Navigator.of(context).popUntil((route) {
          return route.isFirst ||
              !route.settings.name?.contains('RouteDetail') == true;
        });
      }
    });
  }

  /// Cleanup realtime listeners
  void _cleanupRealtimeListeners() {
    // Socket service handles cleanup globally, no need to remove specific listeners here
  }

  /// Handle khi chọn task
  void _handleTaskTap(RoutePoint point, int index) {
    setState(() {
      _selectedPointIndex = index;
    });

    // Animate to selected point using flutter_map
    _mapController?.move(LatLng(point.latitude, point.longitude), 15.0);
  }

  /// Handle hoàn thành task
  Future<void> _handleCompleteTask(RoutePoint point) async {
    final currentImages = _taskImages[point.id] ?? [];

    await showCompleteTaskDialog(
      context: context,
      point: point,
      currentImages: currentImages,
      onComplete: (images, imageUrls) async {
        // Lưu images
        setState(() {
          _taskImages[point.id] = images;
        });

        // Update status qua BLoC với imageUrls (không có weight)
        // BLoC sẽ tự động reload route detail sau khi update thành công
        context.read<RouteBloc>().add(
          UpdatePointStatusRequested(
            routeId: widget.route.id,
            pointId: point.id,
            status: 'completed',
            photoUrls: imageUrls,
          ),
        );

        // Don't auto-show completion dialog - user must tap "Kết thúc chuyến" button
      },
    );
  }

  /// Tự động chuyển sang task tiếp theo chưa hoàn thành
  void _autoSelectNextTask() {
    // Get current route from BLoC state
    final blocState = context.read<RouteBloc>().state;
    WorkerRoute currentRoute = widget.route;

    if (blocState is RoutesLoaded) {
      currentRoute = blocState.routes.firstWhere(
        (r) => r.id == widget.route.id,
        orElse: () => widget.route,
      );
    }

    final nextPendingIndex = currentRoute.points.indexWhere(
      (p) =>
          p.status != 'completed' &&
          p.status != 'collected' &&
          p.status != 'skipped',
    );

    if (nextPendingIndex != -1) {
      setState(() {
        _selectedPointIndex = nextPendingIndex;
      });

      // Animate to next point
      final nextPoint = currentRoute.points[nextPendingIndex];
      _mapController?.move(
        LatLng(nextPoint.latitude, nextPoint.longitude),
        15.0,
      );
    }
  }

  /// Handle navigate đến task
  Future<void> _handleNavigateToTask(RoutePoint point) async {
    await LocationService.navigateToLocation(
      destinationLat: point.latitude,
      destinationLng: point.longitude,
    );
  }

  /// Show dialog hoàn thành route
  void _showRouteCompletionDialog() {
    // Get current route from BLoC state
    final blocState = context.read<RouteBloc>().state;
    WorkerRoute currentRoute = widget.route;

    if (blocState is RoutesLoaded) {
      currentRoute = blocState.routes.firstWhere(
        (r) => r.id == widget.route.id,
        orElse: () => widget.route,
      );
    }

    final completed = currentRoute.points
        .where((p) => p.status == 'completed' || p.status == 'collected')
        .length;

    showRouteCompletionDialog(
      context: context,
      completedPoints: completed,
      totalPoints: currentRoute.points.length,
      onConfirm: (actualDistanceKm, notes) {
        _handleCompleteRoute(actualDistanceKm: actualDistanceKm, notes: notes);
      },
    );
  }

  /// Handle bắt đầu route
  Future<void> _handleStartRoute() async {
    context.read<RouteBloc>().add(
      StartRouteRequested(routeId: widget.route.id),
    );
  }

  /// Handle hoàn thành route
  Future<void> _handleCompleteRoute({
    double? actualDistanceKm,
    String? notes,
  }) async {
    context.read<RouteBloc>().add(
      CompleteRouteRequested(
        routeId: widget.route.id,
        actualDistanceKm: actualDistanceKm,
        notes: notes,
      ),
    );

    // Không pop ngay, để BlocListener xử lý
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<RouteBloc, RouteState>(
        listener: (context, state) {
          if (state is RouteActionSuccess) {
            // Nếu đã hoàn thành route, quay về trang chủ
            if (state.message.contains('hoàn thành lộ trình')) {
              // Show snackbar
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.completed,
                    duration: const Duration(seconds: 2),
                  ),
                );

                // Reload routes list
                context.read<RouteBloc>().add(
                  LoadRoutesRequested(personnelId: widget.route.workerId),
                );

                // Pop về màn hình chính (routes list)
                // Sử dụng popUntil để đảm bảo quay về đúng màn hình
                Navigator.of(context).popUntil((route) {
                  // Pop until we reach a route that's not the detail screen
                  return route.isFirst ||
                      !route.settings.name?.contains('RouteDetail') == true;
                });
              }
            }
          }

          if (state is RouteError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          // Khi update point thành công, show snackbar và auto-select next task
          if (state is RouteActionSuccess &&
              state.message.contains('hoàn thành điểm thu gom')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${state.message}'),
                  backgroundColor: AppColors.completed,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Auto-select next pending task
              _autoSelectNextTask();

              // Force rebuild UI
              setState(() {});
            }
          }
        },
        child: BlocBuilder<RouteBloc, RouteState>(
          builder: (context, state) {
            // Get current route from state, fallback to widget.route
            WorkerRoute currentRoute = widget.route;
            if (state is RoutesLoaded) {
              currentRoute = state.routes.firstWhere(
                (r) => r.id == widget.route.id,
                orElse: () => widget.route,
              );
            }

            return Stack(
              children: [
                // Map full screen - Use currentRoute
                RouteMapView(
                  route: currentRoute,
                  selectedPointIndex: _selectedPointIndex,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),

                // Top gradient overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Header with back button and route info
                SafeArea(
                  child: Column(
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Back button
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: AppColors.textPrimary,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Route info card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            currentRoute.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              currentRoute,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            _getStatusText(currentRoute),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusColor(
                                                currentRoute,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Shift indicator
                                    ShiftIndicator(route: currentRoute),
                                    const SizedBox(height: 4),
                                    Builder(
                                      builder: (context) {
                                        final completed = currentRoute.points
                                            .where(
                                              (p) =>
                                                  p.status == 'collected' ||
                                                  p.status == 'completed',
                                            )
                                            .length;
                                        final total =
                                            currentRoute.points.length;
                                        return Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 14,
                                              color: completed == total
                                                  ? AppColors.completed
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Kết thúc ($completed/$total)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: completed == total
                                                    ? AppColors.completed
                                                    : AppColors.textSecondary,
                                                fontWeight: completed == total
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Refresh button
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: AppColors.textPrimary,
                                ),
                                onPressed: () {
                                  context.read<RouteBloc>().add(
                                    const LoadRoutesRequested(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Task List at bottom - Increased size
                      Container(
                        constraints: const BoxConstraints(maxHeight: 380),
                        child: TaskListView(
                          route: currentRoute,
                          selectedPointIndex: _selectedPointIndex,
                          onTaskTap: _handleTaskTap,
                          onCompleteTask: _handleCompleteTask,
                          onNavigateToTask: _handleNavigateToTask,
                          onStartRoute: _handleStartRoute,
                          onCompleteRoute: () => _showRouteCompletionDialog(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(WorkerRoute route) {
    switch (route.status) {
      case 'pending':
        return AppColors.pending;
      case 'in_progress':
        return AppColors.inProgress;
      case 'completed':
        return AppColors.completed;
      default:
        return AppColors.grey;
    }
  }

  String _getStatusText(WorkerRoute route) {
    switch (route.status) {
      case 'pending':
        return 'Chờ bắt đầu';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      default:
        return route.status;
    }
  }
}
