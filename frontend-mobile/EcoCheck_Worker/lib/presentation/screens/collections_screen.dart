import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../blocs/collection/collection_bloc.dart';
import '../blocs/collection/collection_event.dart';
import '../blocs/collection/collection_state.dart';
import '../widgets/collection_card.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionBloc, CollectionState>(
      builder: (context, state) {
        final allRequests = (state is CollectionsLoaded)
            ? state.allCollections
            : [];
        final pendingRequests = (state is CollectionsLoaded)
            ? state.pendingCollections
            : [];
        final completedRequests = (state is CollectionsLoaded)
            ? state.completedCollections
            : [];

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
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.white),
                onPressed: () {
                  // TODO: Implement search
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_list, color: AppColors.white),
                onPressed: () {
                  // TODO: Implement filter
                },
              ),
            ],
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
          body: RefreshIndicator(
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
        );
      },
    );
  }

  Widget _buildCollectionsList(List requests) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.grey),
            const SizedBox(height: 16),
            const Text(
              AppStrings.noData,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
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
