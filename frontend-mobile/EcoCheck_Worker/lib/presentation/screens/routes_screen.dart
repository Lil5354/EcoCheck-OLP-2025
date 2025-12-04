import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/services/socket_service.dart';
import '../../core/di/injection_container.dart' as di;
import '../../data/models/worker_route.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/route/route_bloc.dart';
import '../blocs/route/route_event.dart';
import '../blocs/route/route_state.dart';
import 'route_detail_screen.dart';

/// Modern Routes Screen với phân ca sáng/chiều/tối
class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String? _statusFilter;
  final SocketService _socketService = di.sl<SocketService>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _setupSocketListeners();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _socketService.removeAllListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    _socketService.onRouteNew((data) {
      if (kDebugMode) {
        print('🆕 New route received: $data');
      }
      _showSnackbar('🆕 Bạn có lộ trình mới!', AppColors.success);
      _loadData();
    });

    _socketService.onRouteAssigned((data) {
      if (mounted) {
        if (kDebugMode) {
          print('📍 Route assigned: $data');
        }
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final authState = context.read<AuthBloc>().state;
    String? personnelId;

    if (authState is Authenticated) {
      personnelId = authState.user.id;
    }

    context.read<RouteBloc>().add(
      LoadRoutesRequested(personnelId: personnelId),
    );
  }

  void _showSnackbar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  List<WorkerRoute> _filterRoutesByShift(
    List<WorkerRoute> routes,
    String shift,
  ) {
    final today = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    return routes.where((route) {
      // Filter by date
      final routeDate = DateTime(
        route.scheduledDate.year,
        route.scheduledDate.month,
        route.scheduledDate.day,
      );

      if (!routeDate.isAtSameMomentAs(today)) return false;

      // Use the new shift detection from WorkerRoute model
      return route.isCorrectShift(shift);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Lộ trình hôm nay',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: _buildShiftTabs(),
        ),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(child: _buildRoutesList()),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DateFormatter.formatDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasFilter = _statusFilter != null;

    return GestureDetector(
      onTap: _showFilterSheet,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasFilter ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.filter_list,
          color: hasFilter ? Colors.white : AppColors.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildShiftTabs() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.white,
      indicatorWeight: 3,
      labelColor: AppColors.white,
      unselectedLabelColor: AppColors.white.withOpacity(0.7),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      tabs: const [
        Tab(icon: Icon(Icons.wb_sunny, size: 20), text: 'Ca sáng'),
        Tab(icon: Icon(Icons.wb_twilight, size: 20), text: 'Ca chiều'),
        Tab(icon: Icon(Icons.nights_stay, size: 20), text: 'Ca tối'),
      ],
    );
  }

  Widget _buildRoutesList() {
    return BlocBuilder<RouteBloc, RouteState>(
      builder: (context, state) {
        if (state is RouteLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is RouteError) {
          return _buildEmptyState(
            icon: Icons.error_outline,
            message: 'Có lỗi xảy ra',
            subtitle: state.message,
          );
        }

        if (state is RoutesLoaded) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildShiftRoutes(state.routes, 'morning'),
              _buildShiftRoutes(state.routes, 'afternoon'),
              _buildShiftRoutes(state.routes, 'evening'),
            ],
          );
        }

        return _buildEmptyState(
          icon: Icons.route,
          message: 'Chưa có lộ trình nào',
          subtitle: 'Lộ trình sẽ hiển thị khi được phân công',
        );
      },
    );
  }

  Widget _buildShiftRoutes(List<WorkerRoute> allRoutes, String shift) {
    final routes = _filterRoutesByShift(allRoutes, shift);

    if (routes.isEmpty) {
      return _buildEmptyState(
        icon: _getShiftIcon(shift),
        message: 'Không có lộ trình ${_getShiftName(shift)}',
        subtitle: 'Chưa có lộ trình nào được phân công cho ca này',
      );
    }

    return Column(
      children: [
        // Shift summary badge
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getShiftColor(shift).withOpacity(0.1),
                _getShiftColor(shift).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getShiftColor(shift).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getShiftIcon(shift),
                color: _getShiftColor(shift),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getShiftName(shift)} (${_getShiftTimeRange(shift)})',
                      style: TextStyle(
                        color: _getShiftColor(shift),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${routes.length} lộ trình được phân công',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getShiftColor(shift),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${routes.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: routes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildRouteCard(routes[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(WorkerRoute route) {
    final statusColor = _getStatusColor(route.status);
    final statusText = _getStatusText(route.status);
    final progress = route.points.isEmpty
        ? 0.0
        : route.points.where((p) => p.status == 'completed').length /
              route.points.length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RouteDetailScreen(route: route)),
        ).then((_) => _loadData());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          route.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.local_shipping,
                    route.vehiclePlate ?? 'N/A',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.location_on,
                    '${route.points.length} điểm thu gom',
                  ),
                  if (route.totalDistance != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.route,
                      '${route.totalDistance!.toStringAsFixed(1)} km',
                    ),
                  ],
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.greyLight,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toInt()}% hoàn thành (${route.points.where((p) => p.status == 'completed').length}/${route.points.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.greyLight),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Lọc theo trạng thái',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            _buildFilterOption(null, 'Tất cả', Icons.all_inclusive),
            _buildFilterOption('planned', 'Chờ bắt đầu', Icons.schedule),
            _buildFilterOption(
              'in_progress',
              'Đang thực hiện',
              Icons.play_circle,
            ),
            _buildFilterOption('completed', 'Hoàn thành', Icons.check_circle),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String? status, String label, IconData icon) {
    final isSelected = _statusFilter == status;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() => _statusFilter = status);
        Navigator.pop(context);
      },
    );
  }

  IconData _getShiftIcon(String shift) {
    switch (shift) {
      case 'morning':
        return Icons.wb_sunny;
      case 'afternoon':
        return Icons.wb_twilight;
      case 'evening':
        return Icons.nights_stay;
      default:
        return Icons.route;
    }
  }

  String _getShiftName(String shift) {
    switch (shift) {
      case 'morning':
        return 'Ca Sáng';
      case 'afternoon':
        return 'Ca Chiều';
      case 'evening':
        return 'Ca Tối';
      default:
        return '';
    }
  }

  String _getShiftTimeRange(String shift) {
    switch (shift) {
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

  Color _getShiftColor(String shift) {
    switch (shift) {
      case 'morning':
        return const Color(0xFFFF9800); // Orange
      case 'afternoon':
        return const Color(0xFF2196F3); // Blue
      case 'evening':
        return const Color(0xFF9C27B0); // Purple
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'planned':
        return AppColors.pending;
      case 'in_progress':
        return AppColors.inProgress;
      case 'completed':
        return AppColors.completed;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'planned':
        return 'Chờ bắt đầu';
      case 'in_progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}
