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
import 'package:eco_check/data/models/schedule_model.dart';
import 'package:eco_check/data/repositories/ecocheck_repository.dart';
import 'package:eco_check/core/di/injection_container.dart' as di;
import 'package:eco_check/presentation/widgets/collection/collection_status_widget.dart';
import 'package:eco_check/presentation/blocs/auth/auth_bloc.dart';
import 'package:eco_check/presentation/blocs/auth/auth_state.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_bloc.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_event.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_state.dart';

class TrackingPage extends StatefulWidget {
  final ScheduleModel? schedule;
  final String? scheduleId;

  const TrackingPage({super.key, this.schedule, this.scheduleId});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  ScheduleModel? _schedule;

  @override
  void initState() {
    super.initState();
    _schedule = widget.schedule;

    // Load fresh data from backend if scheduleId is provided
    if (widget.scheduleId != null || widget.schedule?.id != null) {
      final scheduleId = widget.scheduleId ?? widget.schedule!.id;
      context.read<ScheduleBloc>().add(ScheduleDetailRequested(scheduleId));
    } else {
      // Load all schedules to check if there's an active one
      context.read<ScheduleBloc>().add(const SchedulesLoaded());
    }
  }

  Future<void> _handleAcceptCompletion() async {
    if (_schedule == null) return;

    try {
      // Get user from auth bloc
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;
      final repository = di.sl<EcoCheckRepository>();

      // Call API to award points for completing collection
      await repository.adjustPoints(
        userId: userId,
        points: 50,
        reason: 'Xác nhận hoàn thành thu gom - ${_schedule!.id}',
      );

      // Update local schedule state to mark as claimed
      setState(() {
        _schedule = ScheduleModel(
          id: _schedule!.id,
          citizenId: _schedule!.citizenId,
          scheduledDate: _schedule!.scheduledDate,
          timeSlot: _schedule!.timeSlot,
          wasteType: _schedule!.wasteType,
          estimatedWeight: _schedule!.estimatedWeight,
          actualWeight: _schedule!.actualWeight,
          latitude: _schedule!.latitude,
          longitude: _schedule!.longitude,
          address: _schedule!.address,
          specialInstructions: _schedule!.specialInstructions,
          notes: _schedule!.notes,
          photoUrls: _schedule!.photoUrls,
          status: _schedule!.status,
          priority: _schedule!.priority,
          employeeId: _schedule!.employeeId,
          completedAt: _schedule!.completedAt,
          pointsClaimed: true, // Mark as claimed
          createdAt: _schedule!.createdAt,
          updatedAt: DateTime.now(),
        );
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Bạn đã nhận 50 điểm thưởng!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Reload schedules to update UI
        context.read<ScheduleBloc>().add(const SchedulesLoaded());

        // Wait a bit then navigate back
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.of(context).pop(); // Go back to schedule list
        }
      }
    } catch (e) {
      print('❌ [TrackingPage] Error awarding points: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi nhận điểm: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScheduleBloc, ScheduleState>(
      listener: (context, state) {
        if (state is ScheduleDetailLoaded) {
          // Update local schedule when BLoC receives fresh data
          setState(() {
            _schedule = state.schedule;
          });

          print('📱 [TrackingPage] Schedule updated: ${state.schedule.status}');
          print(
            '📱 [TrackingPage] Points claimed: ${state.schedule.pointsClaimed}',
          );
        } else if (state is ScheduleLoaded && _schedule == null) {
          // When schedules are loaded, pick the first active one
          if (state.schedules.isNotEmpty) {
            final activeSchedule = state.schedules.firstWhere(
              (s) =>
                  s.status == 'pending' ||
                  s.status == 'in_progress' ||
                  s.status == 'completed',
              orElse: () => state.schedules.first,
            );

            // Load detail for this schedule
            context.read<ScheduleBloc>().add(
              ScheduleDetailRequested(activeSchedule.id),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Theo dõi lịch thu gom'),
          actions: [
            if (_schedule != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  final scheduleId = _schedule!.id;
                  context.read<ScheduleBloc>().add(
                    ScheduleDetailRequested(scheduleId),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đang cập nhật trạng thái...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                tooltip: 'Làm mới',
              ),
          ],
        ),
        body: _schedule == null
            ? const Center(
                child: Text(
                  'Hiện tại chưa có lịch thu gom',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Schedule Info Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _schedule!.wasteTypeDisplay,
                                      style: AppTextStyles.h4.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Mã lịch: ${_schedule!.id}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _ScheduleInfoRow(
                            icon: Icons.calendar_today,
                            label: _formatDate(_schedule!.scheduledDate),
                          ),
                          const SizedBox(height: 8),
                          _ScheduleInfoRow(
                            icon: Icons.access_time,
                            label: _schedule!.timeSlotDisplay,
                          ),
                          const SizedBox(height: 8),
                          _ScheduleInfoRow(
                            icon: Icons.location_on,
                            label: _schedule!.address,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Collection Status Widget
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CollectionStatusWidget(
                        status: _schedule!.status,
                        employeeName: _schedule!.employeeId != null
                            ? 'NV-${_schedule!.employeeId}'
                            : null,
                        assignedAt: _schedule!.updatedAt,
                        completedAt: _schedule!.completedAt,
                        onAcceptCompletion: _handleAcceptCompletion,
                        isAccepted: _schedule!.pointsClaimed,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Additional Info Card
                    if (_schedule?.estimatedWeight != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thông tin bổ sung',
                                style: AppTextStyles.h5.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _InfoRow(
                                icon: Icons.scale,
                                label: 'Khối lượng ước tính',
                                value:
                                    '${_schedule?.estimatedWeight?.toStringAsFixed(1) ?? '0.0'} kg',
                              ),
                              if (_schedule?.actualWeight != null) ...[
                                const SizedBox(height: 12),
                                _InfoRow(
                                  icon: Icons.check_circle,
                                  label: 'Khối lượng thực tế',
                                  value:
                                      '${_schedule?.actualWeight?.toStringAsFixed(1) ?? '0.0'} kg',
                                ),
                              ],
                              if (_schedule?.specialInstructions != null) ...[
                                const SizedBox(height: 12),
                                _InfoRow(
                                  icon: Icons.note,
                                  label: 'Ghi chú đặc biệt',
                                  value: _schedule?.specialInstructions ?? '',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
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

/// Schedule Info Row for header
class _ScheduleInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ScheduleInfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }
}

/// Info Row widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
