import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/worker_route.dart';
import '../../data/services/location_service.dart';
import '../blocs/route/route_bloc.dart';
import '../blocs/route/route_event.dart';
import '../blocs/route/route_state.dart';
import '../widgets/route/route_map_view.dart';
import '../widgets/route/task_list_view.dart';
import '../widgets/route/complete_task_dialog.dart';
import '../widgets/route/route_completion_dialog.dart';

/// Route Detail Screen - ĐÃ TÁCH LOGIC RA CÁC FILE NHỎ
///
/// Structure:
/// - RouteMapView: Google Maps (route_map_view.dart)
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
  GoogleMapController? _mapController;
  int? _selectedPointIndex;
  final Map<String, List<XFile>> _taskImages = {};
  bool _hasShownCompletionDialog = false;

  @override
  void initState() {
    super.initState();
    _checkAutoCompletion();
  }

  /// Check xem có cần show completion dialog không
  void _checkAutoCompletion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_areAllTasksCompleted() && !_hasShownCompletionDialog) {
        _hasShownCompletionDialog = true;
        _showRouteCompletionDialog();
      }
    });
  }

  bool _areAllTasksCompleted() {
    return widget.route.points.every((p) => p.status == 'collected');
  }

  /// Handle khi chọn task
  void _handleTaskTap(RoutePoint point, int index) {
    setState(() {
      _selectedPointIndex = index;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(point.latitude, point.longitude), 15),
    );
  }

  /// Handle hoàn thành task
  Future<void> _handleCompleteTask(RoutePoint point) async {
    final currentImages = _taskImages[point.id] ?? [];

    await showCompleteTaskDialog(
      context: context,
      point: point,
      currentImages: currentImages,
      onComplete: (images) async {
        // Lưu images
        setState(() {
          _taskImages[point.id] = images;
        });

        // Update status qua BLoC
        context.read<RouteBloc>().add(
          UpdatePointStatusRequested(
            routeId: widget.route.id,
            pointId: point.id,
            status: 'collected',
          ),
        );

        // Show success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Đã hoàn thành điểm thu gom\n📍 ${point.address}',
              ),
              backgroundColor: AppColors.completed,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Check xem đã hoàn thành hết chưa
        if (_areAllTasksCompleted() && !_hasShownCompletionDialog) {
          _hasShownCompletionDialog = true;
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _showRouteCompletionDialog();
          }
        }
      },
    );
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
    final completed = widget.route.points
        .where((p) => p.status == 'collected')
        .length;

    showRouteCompletionDialog(
      context: context,
      completedPoints: completed,
      totalPoints: widget.route.points.length,
      onConfirm: () {
        _handleCompleteRoute();
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
  Future<void> _handleCompleteRoute() async {
    context.read<RouteBloc>().add(
      CompleteRouteRequested(routeId: widget.route.id),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Đã hoàn thành lộ trình!'),
          backgroundColor: AppColors.completed,
        ),
      );

      // Quay lại màn hình trước
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<RouteBloc, RouteState>(
        listener: (context, state) {
          if (state is RouteActionSuccess) {
            // Re-check completion sau khi update
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_areAllTasksCompleted() && !_hasShownCompletionDialog) {
                _hasShownCompletionDialog = true;
                _showRouteCompletionDialog();
              }
            });
          }
        },
        child: Stack(
          children: [
            // Map full screen
            RouteMapView(
              route: widget.route,
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
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
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
                            child: BlocBuilder<RouteBloc, RouteState>(
                              builder: (context, state) {
                                int completed = widget.route.points
                                    .where((p) => p.status == 'collected')
                                    .length;
                                int total = widget.route.points.length;

                                if (state is RoutesLoaded) {
                                  final currentRoute = state.routes.firstWhere(
                                    (r) => r.id == widget.route.id,
                                    orElse: () => widget.route,
                                  );
                                  completed = currentRoute.points
                                      .where((p) => p.status == 'collected')
                                      .length;
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.route.name,
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
                                            color: _getStatusColor()
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            _getStatusText(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusColor(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
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
                                    ),
                                  ],
                                );
                              },
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

                  // Task List at bottom
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: BlocBuilder<RouteBloc, RouteState>(
                      builder: (context, state) {
                        WorkerRoute currentRoute = widget.route;

                        if (state is RoutesLoaded) {
                          currentRoute = state.routes.firstWhere(
                            (r) => r.id == widget.route.id,
                            orElse: () => widget.route,
                          );
                        }

                        return TaskListView(
                          route: currentRoute,
                          selectedPointIndex: _selectedPointIndex,
                          onTaskTap: _handleTaskTap,
                          onCompleteTask: _handleCompleteTask,
                          onNavigateToTask: _handleNavigateToTask,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Color _getStatusColor() {
    switch (widget.route.status) {
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

  String _getStatusText() {
    switch (widget.route.status) {
      case 'pending':
        return 'Chờ bắt đầu';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      default:
        return widget.route.status;
    }
  }

  Widget? _buildFloatingActionButton() {
    if (widget.route.status == 'pending') {
      return FloatingActionButton.extended(
        onPressed: _handleStartRoute,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Bắt đầu'),
      );
    } else if (widget.route.status == 'in_progress') {
      final completed = widget.route.points
          .where((p) => p.status == 'collected')
          .length;
      final total = widget.route.points.length;

      return FloatingActionButton.extended(
        onPressed: completed == total ? _handleCompleteRoute : null,
        backgroundColor: completed == total
            ? AppColors.completed
            : AppColors.grey,
        icon: const Icon(Icons.check_circle),
        label: Text('Kết thúc ($completed/$total)'),
      );
    }

    return null;
  }
}
