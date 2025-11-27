import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/di/injection_container.dart';
import 'package:eco_check/presentation/blocs/statistics/statistics_bloc.dart';
import 'package:eco_check/presentation/blocs/statistics/statistics_event.dart';
import 'package:eco_check/presentation/blocs/statistics/statistics_state.dart';
import 'package:eco_check/presentation/blocs/auth/auth_bloc.dart';
import 'package:eco_check/presentation/blocs/auth/auth_state.dart';
import 'widgets/stat_card.dart';
import 'widgets/monthly_chart.dart';
import 'widgets/waste_type_distribution.dart';
import 'widgets/achievements_list.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = sl<StatisticsBloc>();
        // Get userId from AuthBloc
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          bloc.add(LoadStatisticsSummary(authState.user.id));
        }
        return bloc;
      },
      child: const _StatisticsPageContent(),
    );
  }
}

class _StatisticsPageContent extends StatelessWidget {
  const _StatisticsPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.statistics),
        actions: [
          BlocBuilder<StatisticsBloc, StatisticsState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is Authenticated) {
                    context.read<StatisticsBloc>().add(
                      RefreshStatistics(authState.user.id),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<StatisticsBloc, StatisticsState>(
        builder: (context, state) {
          if (state is StatisticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StatisticsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final authState = context.read<AuthBloc>().state;
                      if (authState is Authenticated) {
                        context.read<StatisticsBloc>().add(
                          LoadStatisticsSummary(authState.user.id),
                        );
                      }
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is StatisticsLoaded) {
            final summary = state.summary;

            // Check if we have any data
            final hasMonthlyData = summary.monthlyData.isNotEmpty;
            final hasWasteData = summary.wasteDistribution.isNotEmpty;
            final hasAnyData =
                summary.totalWasteThisMonth > 0 ||
                summary.totalCO2SavedThisMonth > 0 ||
                hasMonthlyData ||
                hasWasteData;

            if (!hasAnyData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có dữ liệu thống kê',
                      style: AppTextStyles.h4.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy tạo lịch thu gom để bắt đầu!',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  context.read<StatisticsBloc>().add(
                    RefreshStatistics(authState.user.id),
                  );
                }
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary Cards
                  Text('Tổng quan tháng này', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.delete_outline,
                          value: summary.totalWasteThisMonth.toStringAsFixed(0),
                          unit: 'kg',
                          label: 'Rác đã thu',
                          color: const Color(0xFF2ECC71),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.eco,
                          value: summary.totalCO2SavedThisMonth.toStringAsFixed(
                            0,
                          ),
                          unit: 'kg',
                          label: 'CO2 tiết kiệm',
                          color: const Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Monthly Chart
                  Text('Biểu đồ 6 tháng gần đây', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  MonthlyChart(data: summary.monthlyData),

                  const SizedBox(height: 24),

                  // Waste Type Distribution
                  Text('Phân loại rác', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  WasteTypeDistribution(data: summary.wasteDistribution),

                  const SizedBox(height: 24),

                  // Achievements
                  Text('Thành tựu', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  const AchievementsList(),
                ],
              ),
            );
          }

          return const Center(child: Text('Chưa có dữ liệu'));
        },
      ),
    );
  }
}
