import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/transactions/providers/transaction_provider.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';
import 'package:expense_tracker/features/categories/providers/category_provider.dart';
import 'package:expense_tracker/shared/widgets/transaction_card.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  bool? _isIgnoredFilter;
  String? _categoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    final notifier = ref.read(transactionProvider.notifier);
    notifier.applyFilters(
      ref.read(transactionProvider).filters.copyWith(search: value, clearSearch: value.isEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: Text('Transaksi', style: Theme.of(context).textTheme.headlineSmall),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(108),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    // Search
                    TextField(
                      controller: _searchController,
                      onChanged: _applySearch,
                      decoration: InputDecoration(
                        hintText: 'Cari merchant...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _applySearch('');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Filter chips row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Semua',
                            selected: _isIgnoredFilter == null,
                            onTap: () {
                              setState(() => _isIgnoredFilter = null);
                              ref.read(transactionProvider.notifier).applyFilters(
                                state.filters.copyWith(clearIgnored: true),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Aktif',
                            selected: _isIgnoredFilter == false,
                            onTap: () {
                              setState(() => _isIgnoredFilter = false);
                              ref.read(transactionProvider.notifier).applyFilters(
                                state.filters.copyWith(isIgnored: false),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Diabaikan',
                            selected: _isIgnoredFilter == true,
                            onTap: () {
                              setState(() => _isIgnoredFilter = true);
                              ref.read(transactionProvider.notifier).applyFilters(
                                state.filters.copyWith(isIgnored: true),
                              );
                            },
                          ),
                          if (categories.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _CategoryFilterChip(
                              categories: categories,
                              selectedId: _categoryFilter,
                              onSelected: (id) {
                                setState(() => _categoryFilter = id);
                                ref.read(transactionProvider.notifier).applyFilters(
                                  id == null
                                      ? state.filters.copyWith(clearCategory: true)
                                      : state.filters.copyWith(categoryId: id),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _buildList(state),
      ),
    );
  }

  Widget _buildList(TransactionListState state) {
    if (state.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, style: const TextStyle(color: AppColors.error)),
            TextButton(
              onPressed: () => ref.read(transactionProvider.notifier).fetch(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textDisabled),
            SizedBox(height: 12),
            Text('Tidak ada transaksi', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(transactionProvider.notifier).fetch(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.transactions.length + (state.filters.page < state.totalPages ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == state.transactions.length) {
            // Load more trigger
            ref.read(transactionProvider.notifier).loadMore();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final tx = state.transactions[index];
          return TransactionCard(
            transaction: tx,
            showIgnoreSlide: true,
            onIgnoreToggle: (isIgnored) {
              ref.read(transactionProvider.notifier).updateTransaction(
                tx.id,
                isIgnored: isIgnored,
              );
            },
            onCategoryTap: () => _showCategoryPicker(context, tx),
          );
        },
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, TransactionModel tx) {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Kategori', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(tx.merchant, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            ...categories.map((cat) => ListTile(
              leading: CircleAvatar(
                radius: 10,
                backgroundColor: cat.colorValue,
              ),
              title: Text(cat.name),
              trailing: tx.categoryId == cat.id
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);
                ref.read(transactionProvider.notifier).updateTransaction(
                  tx.id,
                  categoryId: cat.id,
                );
              },
            )),
            ListTile(
              leading: const CircleAvatar(radius: 10, backgroundColor: AppColors.textDisabled),
              title: const Text('Tanpa Kategori'),
              onTap: () {
                Navigator.pop(context);
                ref.read(transactionProvider.notifier).updateTransaction(
                  tx.id,
                  categoryId: null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final List categories;
  final String? selectedId;
  final void Function(String?) onSelected;

  const _CategoryFilterChip({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Semua Kategori'),
                onTap: () { Navigator.pop(context); onSelected(null); },
              ),
              ...categories.map((c) => ListTile(
                leading: CircleAvatar(radius: 8, backgroundColor: c.colorValue),
                title: Text(c.name),
                onTap: () { Navigator.pop(context); onSelected(c.id); },
              )),
            ],
          ),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selectedId != null ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedId != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kategori',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selectedId != null ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                size: 16,
                color: selectedId != null ? Colors.white : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
