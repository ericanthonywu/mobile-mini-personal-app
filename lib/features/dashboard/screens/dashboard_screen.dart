import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/budget/providers/budget_provider.dart';
import 'package:expense_tracker/features/budget/models/budget_model.dart';
import 'package:expense_tracker/features/transactions/providers/transaction_provider.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';
import 'package:expense_tracker/shared/widgets/transaction_card.dart';
import 'package:expense_tracker/features/dashboard/widgets/expense_chart.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);
    final chartAsync = ref.watch(budgetChartProvider);
    final pollState = ref.watch(pollProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(budgetProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(budgetChartProvider);
          // Wait briefly so the spinner is visible
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, ref),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Budget cards
                  budgetAsync.when(
                    loading: () => _buildBudgetSkeleton(),
                    error: (e, _) => _buildError(e.toString(), () => ref.invalidate(budgetProvider)),
                    data: (budget) => Column(
                      children: [
                        _BudgetCard(
                          label: 'Minggu Ini',
                          period: budget.week,
                        ),
                        const SizedBox(height: 12),
                        _BudgetCard(
                          label: 'Bulan Ini',
                          period: budget.month,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Expense comparison
                  budgetAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (budget) => _ExpenseComparisonCard(budget: budget),
                  ),
                  const SizedBox(height: 20),

                  // Expense chart
                  chartAsync.when(
                    loading: () => _SkeletonBox(height: 280, borderRadius: 16),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (chart) => ExpenseChart(chart: chart),
                  ),
                  const SizedBox(height: 20),

                  // Recent transactions header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Transaksi Terbaru',
                          style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.go('/transactions'),
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Recent transactions list
                  recentAsync.when(
                    loading: () => Column(
                      children: List.generate(3, (_) => const _TransactionSkeleton()),
                    ),
                    error: (e, _) => _buildError(e.toString(), () => ref.invalidate(recentTransactionsProvider)),
                    data: (txs) => txs.isEmpty
                        ? _EmptyState()
                        : Column(
                            children: txs.map((tx) => TransactionCard(
                              transaction: tx,
                              onIgnoreToggle: null, // read-only on dashboard
                            )).toList(),
                          ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _SyncFab(pollState: pollState, ref: ref),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selamat datang 👋',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          Text('Expense Tracker',
              style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
          onPressed: () => ref.read(authProvider.notifier).logout(),
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildBudgetSkeleton() {
    return Column(
      children: [
        _SkeletonBox(height: 120, borderRadius: 16),
        const SizedBox(height: 12),
        _SkeletonBox(height: 120, borderRadius: 16),
      ],
    );
  }

  Widget _buildError(String msg, VoidCallback retry) {
    return Center(
      child: Column(
        children: [
          Text(msg, style: const TextStyle(color: AppColors.error)),
          TextButton(onPressed: retry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String label;
  final BudgetPeriod period;

  const _BudgetCard({required this.label, required this.period});

  Color get _progressColor {
    if (period.isOverBudget) return AppColors.error;
    if (period.percentUsed >= 80) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _progressColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${period.percentUsed}%',
                  style: TextStyle(
                    color: _progressColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Terpakai', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(period.realSpent),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _progressColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Anggaran', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(period.budget),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: period.percentUsed / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(_progressColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            period.isOverBudget
                ? 'Melebihi anggaran ${CurrencyFormatter.format(period.realSpent - period.budget)}'
                : 'Sisa ${CurrencyFormatter.format(period.remaining)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _progressColor),
          ),
        ],
      ),
    );
  }
}

class _ExpenseComparisonCard extends StatelessWidget {
  final BudgetSummaryModel budget;

  const _ExpenseComparisonCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Perbandingan Pengeluaran (Bulan Ini)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _ComparisonRow(
            label: 'Total Pengeluaran',
            amount: budget.month.totalSpent,
            color: AppColors.textPrimary,
          ),
          const SizedBox(height: 10),
          _ComparisonRow(
            label: 'Pengeluaran Nyata',
            subtitle: '(tanpa yang diabaikan)',
            amount: budget.month.realSpent,
            color: AppColors.primary,
          ),
          if (budget.month.ignoredAmount > 0) ...[
            const SizedBox(height: 10),
            _ComparisonRow(
              label: 'Diabaikan',
              amount: budget.month.ignoredAmount,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final int amount;
  final Color color;

  const _ComparisonRow({
    required this.label,
    this.subtitle,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _SyncFab extends StatelessWidget {
  final PollState pollState;
  final WidgetRef ref;

  const _SyncFab({required this.pollState, required this.ref});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: pollState.isPolling
          ? null
          : () async {
              await ref.read(pollProvider.notifier).triggerPoll();
              final state = ref.read(pollProvider);
              if (!context.mounted) return;
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error!), backgroundColor: AppColors.error),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.lastMessage ?? 'Sync selesai')),
                );
                ref.invalidate(budgetProvider);
                ref.invalidate(recentTransactionsProvider);
                ref.invalidate(budgetChartProvider);
              }
            },
      tooltip: 'Sinkronkan Email',
      child: pollState.isPolling
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : const Icon(Icons.sync_rounded),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text('Belum ada transaksi',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                )),
            const SizedBox(height: 4),
            Text('Tap tombol sync untuk mengambil email BCA',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double borderRadius;

  const _SkeletonBox({required this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _TransactionSkeleton extends StatelessWidget {
  const _TransactionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
