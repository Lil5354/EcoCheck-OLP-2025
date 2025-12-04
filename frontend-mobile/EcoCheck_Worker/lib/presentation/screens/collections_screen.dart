/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../blocs/collection/collection_bloc.dart';
import '../blocs/collection/collection_event.dart';
import '../blocs/collection/collection_state.dart';
import '../widgets/collection_card.dart';
import '../widgets/date_filter_bottom_sheet.dart';
import '../widgets/modern_search_bar.dart';
import '../widgets/filter_chip_bar.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    context.read<CollectionBloc>().add(LoadCollectionsRequested());
  }

  void _showDateFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DateFilterBottomSheet(
        currentStartDate: _startDate,
        currentEndDate: _endDate,
        onApply: (start, end) {
          setState(() {
            _startDate = start;
            _endDate = end;
          });
        },
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
    });
  }

  List _filterCollections(List collections) {
    var filtered = collections;

    // Filter by date range
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((collection) {
        final createdAt = DateTime.parse(collection.createdAt);
        final collectionDate = DateTime(
          createdAt.year,
          createdAt.month,
          createdAt.day,
        );
        final start = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
        );
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

        return (collectionDate.isAtSameMomentAs(start) ||
                collectionDate.isAfter(start)) &&
            (collectionDate.isAtSameMomentAs(end) ||
                collectionDate.isBefore(end));
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((collection) {
        return collection.address?.toLowerCase().contains(query) == true ||
            collection.wasteType?.toLowerCase().contains(query) == true ||
            collection.description?.toLowerCase().contains(query) == true;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionBloc, CollectionState>(
      builder: (context, state) {
        final allRequests = (state is CollectionsLoaded)
            ? _filterCollections(state.allCollections)
            : [];
        final pendingRequests = (state is CollectionsLoaded)
            ? _filterCollections(state.pendingCollections)
            : [];
        final completedRequests = (state is CollectionsLoaded)
            ? _filterCollections(state.completedCollections)
            : [];

        final hasActiveFilter = _startDate != null || _searchQuery.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: const Text(
              AppStrings.collectionRequests,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.white,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withOpacity(0.7),
              tabs: [
                Tab(text: 'Tất cả (${allRequests.length})'),
                Tab(text: 'Đang xử lý (${pendingRequests.length})'),
                Tab(text: 'Hoàn thành (${completedRequests.length})'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Modern search bar
              ModernSearchBar(
                hint: 'Tìm theo địa chỉ, loại rác...',
                initialValue: _searchQuery,
                onSearch: (value) => setState(() => _searchQuery = value),
                onClear: () => setState(() => _searchQuery = ''),
              ),

              // Filter chips
              FilterChipBar(
                startDate: _startDate,
                endDate: _endDate,
                onDateFilterTap: _showDateFilterSheet,
                onClearAll: hasActiveFilter ? _clearAllFilters : null,
              ),

              // Tab content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCollectionsList(allRequests),
                      _buildCollectionsList(pendingRequests),
                      _buildCollectionsList(completedRequests),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollectionsList(List requests) {
    final hasActiveFilter = _startDate != null || _searchQuery.isNotEmpty;

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasActiveFilter ? Icons.search_off : Icons.inbox_outlined,
              size: 64,
              color: AppColors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              hasActiveFilter
                  ? 'Không tìm thấy yêu cầu nào'
                  : AppStrings.noData,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (hasActiveFilter) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Xóa bộ lọc'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return CollectionCard(
          request: request,
          onTap: () {
            // TODO: Navigate to detail
          },
        );
      },
    );
  }
}
