import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/constants/app_constants.dart';
import 'package:eco_check/data/models/schedule_model.dart';
import 'create_schedule_page.dart';
import 'schedule_detail_page.dart';

class ScheduleListPage extends StatefulWidget {
  const ScheduleListPage({super.key});

  @override
  State<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mock data
  List<ScheduleModel> get _mockSchedules => [
    ScheduleModel(
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
    ),
    ScheduleModel(
      id: '2',
      citizenId: 'user123',
      scheduledDate: DateTime.now().add(const Duration(days: 5)),
      timeSlot: AppConstants.timeSlotAfternoon,
      wasteType: AppConstants.wasteTypeOrganic,
      estimatedWeight: 3.2,
      latitude: 10.762622,
      longitude: 106.660172,
      address: '456 Lê Lợi, Quận 1, TP.HCM',
      status: AppConstants.statusPending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ScheduleModel(
      id: '3',
      citizenId: 'user123',
      scheduledDate: DateTime.now().subtract(const Duration(days: 3)),
      timeSlot: AppConstants.timeSlotMorning,
      wasteType: AppConstants.wasteTypeHazardous,
      estimatedWeight: 2.0,
      actualWeight: 1.8,
      latitude: 10.762622,
      longitude: 106.660172,
      address: '789 Trần Hưng Đạo, Quận 5, TP.HCM',
      status: AppConstants.statusCompleted,
      employeeId: 'emp001',
      completedAt: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  List<ScheduleModel> _getSchedulesByStatus(String status) {
    return _mockSchedules.where((s) => s.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.schedule),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chờ xác nhận'),
            Tab(text: 'Đã xác nhận'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ScheduleList(
            schedules: _getSchedulesByStatus(AppConstants.statusPending),
            emptyMessage: 'Không có lịch chờ xác nhận',
          ),
          _ScheduleList(
            schedules: _getSchedulesByStatus(AppConstants.statusConfirmed),
            emptyMessage: 'Không có lịch đã xác nhận',
          ),
          _ScheduleList(
            schedules: _getSchedulesByStatus(AppConstants.statusCompleted),
            emptyMessage: 'Chưa có lịch hoàn thành',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateSchedulePage()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Đặt lịch mới'),
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  final List<ScheduleModel> schedules;
  final String emptyMessage;

  const _ScheduleList({required this.schedules, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        return _ScheduleCard(schedule: schedules[index]);
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;

  const _ScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ScheduleDetailPage(scheduleId: schedule.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.getWasteTypeColor(
                        schedule.wasteType,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppColors.getWasteTypeColor(schedule.wasteType),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.wasteTypeDisplay,
                          style: AppTextStyles.h5,
                        ),
                        Text(
                          '${schedule.estimatedWeight?.toStringAsFixed(1)}kg',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
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
                      color: AppColors.getStatusColor(
                        schedule.status,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      schedule.statusDisplay,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.getStatusColor(schedule.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDate(schedule.scheduledDate)} - ${schedule.timeSlotDisplay}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      schedule.address,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
