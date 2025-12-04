/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/constants/app_constants.dart';
import 'package:eco_check/data/models/schedule_model.dart';
import 'package:eco_check/presentation/blocs/auth/auth_bloc.dart';
import 'package:eco_check/presentation/blocs/auth/auth_state.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_bloc.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_event.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_state.dart';
import '../schedule/schedule_list_page.dart';
import '../tracking/tracking_page.dart';
import '../statistics/statistics_page.dart';
import '../profile/profile_page.dart';
import 'widgets/upcoming_schedule_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/statistics_summary_card.dart';
import 'widgets/eco_tips_carousel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeTabPage(),
    ScheduleListPage(),
    TrackingPage(),
    StatisticsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: AppStrings.schedule,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Theo dõi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: AppStrings.statistics,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}

/// Home Tab Page with all content
class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  @override
  void initState() {
    super.initState();
    // Load user's schedules from backend (after first frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ScheduleBloc>().add(const SchedulesLoaded());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get user info
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is Authenticated
        ? authState.user.fullName
        : 'User';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.recycling,
                size: 20,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(AppStrings.appName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, scheduleState) {
          // Find upcoming schedule (scheduled, confirmed or pending, future date)
          ScheduleModel? upcomingSchedule;
          if (scheduleState is ScheduleLoaded) {
            final now = DateTime.now();
            final futureSchedules = scheduleState.schedules.where((s) {
              return s.scheduledDate.isAfter(now) &&
                  (s.status == AppConstants.statusScheduled ||
                      s.status == AppConstants.statusConfirmed ||
                      s.status == AppConstants.statusPending);
            }).toList();

            futureSchedules.sort(
              (a, b) => a.scheduledDate.compareTo(b.scheduledDate),
            );
            upcomingSchedule = futureSchedules.isNotEmpty
                ? futureSchedules.first
                : null;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Text(
                  '${AppStrings.welcome}, $userName! 👋',
                  style: AppTextStyles.h3,
                ),

                const SizedBox(height: 24),

                // Upcoming Schedule Card
                Text(AppStrings.upcomingSchedule, style: AppTextStyles.h4),
                const SizedBox(height: 12),
                if (scheduleState is ScheduleLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (upcomingSchedule != null)
                  UpcomingScheduleCard(
                    schedule: upcomingSchedule,
                    daysUntil: upcomingSchedule.scheduledDate
                        .difference(DateTime.now())
                        .inDays,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 48,
                            color: AppColors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có lịch thu gom nào',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Quick Actions
                Text(AppStrings.quickActions, style: AppTextStyles.h4),
                const SizedBox(height: 12),
                const QuickActionsGrid(),

                const SizedBox(height: 24),

                // Statistics Summary
                Text(
                  '${AppStrings.statistics} tháng này',
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: 12),
                const StatisticsSummaryCard(),

                const SizedBox(height: 24),

                // Eco Tips
                Text(AppStrings.ecoTips, style: AppTextStyles.h4),
                const SizedBox(height: 12),
                const EcoTipsCarousel(),
              ],
            ),
          );
        },
      ),
    );
  }
}
