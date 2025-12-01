import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/presentation/blocs/auth/auth_bloc.dart';
import 'package:eco_check/presentation/blocs/auth/auth_state.dart';
import 'package:eco_check/presentation/blocs/gamification/gamification_bloc.dart';
import 'package:eco_check/presentation/blocs/gamification/gamification_event.dart';
import 'package:eco_check/presentation/blocs/gamification/gamification_state.dart';
import 'widgets/badges_tab.dart';
import 'widgets/leaderboard_tab.dart';
import 'widgets/user_stats_header.dart';

/// Gamification Page with BLoC
class GamificationPageBloc extends StatefulWidget {
  const GamificationPageBloc({super.key});

  @override
  State<GamificationPageBloc> createState() => _GamificationPageBlocState();
}

class _GamificationPageBlocState extends State<GamificationPageBloc>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Get userId from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<GamificationBloc>().add(LoadUserStats(authState.user.id));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điểm xanh & Bảng xếp hạng'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Huy hiệu'),
            Tab(text: 'Xếp hạng'),
          ],
        ),
      ),
      body: BlocConsumer<GamificationBloc, GamificationState>(
        listener: (context, state) {
          if (state is GamificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is GamificationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GamificationDataLoaded) {
            return Column(
              children: [
                UserStatsHeader(
                  points: state.points,
                  rank: state.rank,
                  position: state.position,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      BadgesTab(badges: state.badges),
                      LeaderboardTab(entries: state.leaderboard),
                    ],
                  ),
                ),
              ],
            );
          }

          return _ErrorView(
            onRetry: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                context.read<GamificationBloc>().add(
                  LoadUserStats(authState.user.id),
                );
              }
            },
          );
        },
      ),
    );
  }
}

/// Error View Widget
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Không thể tải dữ liệu',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
