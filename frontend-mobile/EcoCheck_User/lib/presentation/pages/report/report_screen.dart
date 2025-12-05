/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/ecocheck_repository.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/report/create_report_dialog.dart';
import '../../../core/constants/color_constants.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = di.sl<EcoCheckRepository>();
  List<Map<String, dynamic>> _violations = [];
  List<Map<String, dynamic>> _damages = [];
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getUserId();
    _loadReports();
  }

  void _getUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _userId = authState.user.id;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Call API to load user's incidents
      final reports = await _repository.getUserIncidents(_userId!);

      setState(() {
        _violations = reports
            .where((r) => r['report_category'] == 'violation')
            .toList();
        _damages = reports
            .where((r) => r['report_category'] == 'damage')
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải báo cáo: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateReportDialog(String category) async {
    await showDialog(
      context: context,
      builder: (context) => CreateReportDialog(category: category),
    );

    // Reload reports after dialog closes
    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Vi phạm'),
            Tab(icon: Icon(Icons.build_circle_outlined), text: 'Hư hỏng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Vi phạm
          _buildReportList(
            category: 'violation',
            reports: _violations,
            emptyIcon: Icons.verified_outlined,
            emptyMessage: 'Chưa có báo cáo vi phạm',
          ),
          // Tab Hư hỏng
          _buildReportList(
            category: 'damage',
            reports: _damages,
            emptyIcon: Icons.handyman_outlined,
            emptyMessage: 'Chưa có báo cáo hư hỏng',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final category = _tabController.index == 0 ? 'violation' : 'damage';
          _showCreateReportDialog(category);
        },
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0 ? 'Báo cáo vi phạm' : 'Báo cáo hư hỏng',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildReportList({
    required String category,
    required List<Map<String, dynamic>> reports,
    required IconData emptyIcon,
    required String emptyMessage,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateReportDialog(category),
              icon: const Icon(Icons.add),
              label: const Text('Tạo báo cáo mới'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return _buildReportItem(report);
        },
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report) {
    final status = report['status'] ?? 'pending';
    final type = report['type'] ?? '';
    final description = report['description'] ?? '';
    final createdAt = report['created_at'] != null
        ? DateTime.parse(report['created_at'])
        : DateTime.now();
    final imageUrls = report['image_urls'] as List<dynamic>? ?? [];

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Chờ xử lý';
        statusIcon = Icons.schedule;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusText = 'Đang xử lý';
        statusIcon = Icons.sync;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusText = 'Đã giải quyết';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Từ chối';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showReportDetail(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Type & Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getTypeLabel(type),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              // Images preview
              if (imageUrls.isNotEmpty)
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length > 3 ? 3 : imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                imageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image),
                              ),
                              if (imageUrls.length > 3 && index == 2)
                                Container(
                                  color: Colors.black54,
                                  child: Center(
                                    child: Text(
                                      '+${imageUrls.length - 2}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (imageUrls.isNotEmpty) const SizedBox(height: 12),
              // Footer: Date & Location
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (report['location_address'] != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report['location_address'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    const typeMap = {
      'illegal_dump': 'Vứt rác trái phép',
      'wrong_classification': 'Phân loại sai',
      'overloaded_bin': 'Thùng rác quá tải',
      'littering': 'Xả rác bừa bãi',
      'burning_waste': 'Đốt rác',
      'worker_not_collected': 'Nhân viên không dọn',
      'broken_bin': 'Thùng rác hỏng',
      'damaged_equipment': 'Thiết bị hư hỏng',
      'road_damage': 'Đường bị hư',
      'facility_damage': 'Cơ sở vật chất hư hỏng',
    };
    return typeMap[type] ?? type;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} phút trước';
      }
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showReportDetail(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTypeLabel(report['type'] ?? '')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Trạng thái', report['status'] ?? 'pending'),
              const SizedBox(height: 8),
              _buildDetailRow('Mô tả', report['description'] ?? ''),
              if (report['location_address'] != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Địa chỉ', report['location_address']),
              ],
              if (report['resolution_notes'] != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                const Text(
                  'Ghi chú xử lý:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(report['resolution_notes']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
