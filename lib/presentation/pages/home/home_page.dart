import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/constants/app_constants.dart';
import 'package:eco_check/data/models/schedule_model.dart';
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
class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key});

  // Mock upcoming schedule
  ScheduleModel get _mockUpcomingSchedule => ScheduleModel(
    id: '1',
    citizenId: 'user123',
    scheduledDate: DateTime.now().add(const Duration(days: 2)),
    timeSlot: AppConstants.timeSlotMorning,
    wasteType: AppConstants.wasteTypeRecyclable,
    estimatedWeight: 5.5,
    latitude: 10.762622,
    longitude: 106.660172,
    address: '123 Nguyễn Huệ, Quận 1, TP.HCM',
    status: AppConstants.statusConfirmed,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final upcomingSchedule = _mockUpcomingSchedule;
    final daysUntil = upcomingSchedule.scheduledDate
        .difference(DateTime.now())
        .inDays;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              '${AppStrings.welcome}, Nguyễn Văn A! 👋',
              style: AppTextStyles.h3,
            ),

            const SizedBox(height: 24),

            // Upcoming Schedule Card
            Text(AppStrings.upcomingSchedule, style: AppTextStyles.h4),
            const SizedBox(height: 12),
            UpcomingScheduleCard(
              schedule: upcomingSchedule,
              daysUntil: daysUntil,
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(AppStrings.quickActions, style: AppTextStyles.h4),
            const SizedBox(height: 12),
            const QuickActionsGrid(),

            const SizedBox(height: 24),

            // Statistics Summary
            Text('${AppStrings.statistics} tháng này', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            const StatisticsSummaryCard(),

            const SizedBox(height: 24),

            // Eco Tips
            Text(AppStrings.ecoTips, style: AppTextStyles.h4),
            const SizedBox(height: 12),
            const EcoTipsCarousel(),
          ],
        ),
      ),
    );
  }
}
