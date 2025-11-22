import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/collection_request.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/collection/collection_bloc.dart';
import '../blocs/collection/collection_event.dart';
import '../blocs/collection/collection_state.dart';
import '../blocs/route/route_bloc.dart';
import '../blocs/route/route_event.dart';
import '../blocs/route/route_state.dart';
import '../../data/services/mock_data_service.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/quick_stats_row.dart';
import '../widgets/dashboard/active_route_card.dart';
import '../widgets/dashboard/today_collections_list.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    context.read<CollectionBloc>().add(LoadCollectionsRequested());
    context.read<RouteBloc>().add(LoadRoutesRequested());
  }

  @override
  Widget build(BuildContext context) {
    final stats = MockDataService.getWorkerStatistics();

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final worker = (authState is Authenticated) ? authState.worker : null;

        return BlocBuilder<CollectionBloc, CollectionState>(
          builder: (context, collectionState) {
            final todayRequests = (collectionState is CollectionsLoaded)
                ? collectionState.todayCollections
                : <CollectionRequest>[];
            final isCollectionLoading = collectionState is CollectionLoading;

            return BlocBuilder<RouteBloc, RouteState>(
              builder: (context, routeState) {
                final activeRoute = (routeState is RoutesLoaded)
                    ? routeState.activeRoute
                    : null;

                return Scaffold(
                  backgroundColor: AppColors.background,
                  appBar: AppBar(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xin chào,',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.white,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        Text(
                          worker?.fullName ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.white,
                        ),
                        onPressed: () {
                          // TODO: Navigate to notifications
                        },
                      ),
                    ],
                  ),
                  body: RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with gradient and stats
                          DashboardHeader(stats: stats),

                          const SizedBox(height: 24),

                          // Quick Stats
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: QuickStatsRow(stats: stats),
                          ),

                          const SizedBox(height: 24),

                          // Active Route Card
                          if (activeRoute != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: ActiveRouteCard(route: activeRoute),
                            ),

                          const SizedBox(height: 24),

                          // Today's Collections
                          TodayCollectionsList(
                            todayRequests: todayRequests,
                            isLoading: isCollectionLoading,
                            onViewAll: () {
                              // TODO: Switch to collections tab
                            },
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
