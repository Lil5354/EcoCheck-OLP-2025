import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/constants/app_constants.dart';
import 'package:eco_check/data/models/schedule_model.dart';
import 'package:eco_check/core/di/injection_container.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_bloc.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_event.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_state.dart';
import '../checkin/create_request_page.dart';
import 'schedule_detail_page.dart';

class ScheduleListPage extends StatelessWidget {
  const ScheduleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ScheduleBloc>()..add(const SchedulesLoaded()),
      child: const _ScheduleListView(),
    );
  }
}

class _ScheduleListView extends StatefulWidget {
  const _ScheduleListView();

  @override
  State<_ScheduleListView> createState() => _ScheduleListViewState();
}

class _ScheduleListViewState extends State<_ScheduleListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ScheduleModel> _getSchedulesByStatuses(
    List<ScheduleModel> schedules,
    List<String> statuses,
  ) {
    return schedules.where((s) => statuses.contains(s.status)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.schedule),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đã xác nhận'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
      ),
      body: BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, state) {
          if (state is ScheduleLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ScheduleError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ScheduleBloc>().add(const SchedulesLoaded());
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final schedules = state is ScheduleLoaded
              ? state.schedules
              : <ScheduleModel>[];

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Đã xác nhận (scheduled, confirmed, assigned, in_progress)
              _ScheduleList(
                schedules: _getSchedulesByStatuses(schedules, [
                  AppConstants.statusScheduled,
                  AppConstants.statusConfirmed,
                  AppConstants.statusAssigned,
                  AppConstants.statusInProgress,
                ]),
                emptyMessage: 'Không có lịch chờ xác nhận',
              ),
              // Tab 2: Hoàn thành (completed)
              _ScheduleList(
                schedules: _getSchedulesByStatuses(schedules, [
                  AppConstants.statusCompleted,
                ]),
                emptyMessage: 'Chưa có lịch hoàn thành',
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => sl<ScheduleBloc>(),
                child: const CreateRequestPage(),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Yêu cầu thu gom'),
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
