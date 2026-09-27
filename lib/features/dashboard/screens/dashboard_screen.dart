import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/budget/providers/budget_provider.dart';
import 'package:expense_tracker/features/budget/models/budget_model.dart';
import 'package:expense_tracker/features/transactions/providers/transaction_provider.dart';
import 'package:expense_tracker/shared/widgets/transaction_card.dart';
import 'package:expense_tracker/features/dashboard/widgets/expense_chart.dart';
import 'package:expense_tracker/features/dashboard/widgets/spending_summary_chart.dart';
import 'package:expense_tracker/features/dashboard/widgets/daily_spending_card.dart';
import 'package:expense_tracker/features/dashboard/providers/daily_summary_provider.dart';
import 'package:expense_tracker/shared/widgets/app_error_widget.dart';
import 'package:expense_tracker/features/dashboard/providers/alert_provider.dart';
import 'package:expense_tracker/features/dashboard/widgets/alert_banner.dart';
import 'package:expense_tracker/shared/widgets/app_skeleton.dart';
import 'package:expense_tracker/features/dashboard/providers/daily_chart_provider.dart';
import 'package:expense_tracker/features/dashboard/providers/spending_summary_provider.dart';
import 'package:expense_tracker/features/breakdown/providers/breakdown_provider.dart';
import 'package:expense_tracker/core/utils/notification_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with AutomaticKeepAliveClientMixin {
  DateTime? _lastSyncedAt;

  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshAll() async {
    HapticFeedback.mediumImpact();
    ref.invalidate(budgetProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(budgetChartProvider);
    ref.invalidate(dailySummaryProvider);
    ref.invalidate(alertsProvider);
    ref.invalidate(dailyChartProvider);
    ref.invalidate(spendingSummaryProvider);
    setState(() {
      _lastSyncedAt = DateTime.now();
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Applies a date filter to the transaction provider and navigates to /transactions.
  void _navigateToTransactions(BuildContext context, DateTime from, DateTime to, String label) {
    HapticFeedback.selectionClick();
    final notifier = ref.read(transactionProvider.notifier);
    final currentFilters = ref.read(transactionProvider).filters;
    notifier.applyFilters(
      currentFilters.copyWith(dateFrom: from, dateTo: to, isIgnored: false),
      dateLabel: label,
    );
    context.go('/transactions');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final budgetAsync = ref.watch(budgetProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);
    final chartAsync = ref.watch(budgetChartProvider);
    final pollState = ref.watch(pollProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildAppBar(context, ref),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Last synced status indicator pill
                  if (_lastSyncedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Synced just now',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Parse-failure alert banner
                  ref.watch(alertsProvider).when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (alerts) => alerts.isEmpty
                        ? const SizedBox.shrink()
                        : AlertBanner(alerts: alerts),
                  ),
                  ref.watch(alertsProvider).maybeWhen(
                    data: (alerts) => alerts.isNotEmpty
                        ? const SizedBox(height: 12)
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // Today's Spending Summary (Daily Spending & Top 5)
                  _TappableCard(
                    onTap: () {
                      final now = DateTime.now().toUtc().add(const Duration(hours: 7));
                      final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
                      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
                      _navigateToTransactions(context, todayStart, todayEnd, 'Today');
                    },
                    child: const DailySpendingCard(),
                  ),
                  const SizedBox(height: 20),

                  // Budget Overview Cards
                  budgetAsync.when(
                    loading: () => _buildBudgetSkeleton(),
                    error: (e, _) => AppErrorWidget(
                      error: e,
                      onRetry: () => ref.invalidate(budgetProvider),
                    ),
                    data: (budget) => Column(
                      children: [
                        _TappableCard(
                          onTap: () => _navigateToTransactions(
                            context,
                            budget.week.start,
                            budget.week.end,
                            'This Week',
                          ),
                          child: _BudgetCard(
                            label: 'This Week',
                            period: budget.week,
                            isFeatured: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _TappableCard(
                          onTap: () => _navigateToTransactions(
                            context,
                            budget.month.start,
                            budget.month.end,
                            'This Month',
                          ),
                          child: _BudgetCard(
                            label: 'This Month',
                            period: budget.month,
                            isFeatured: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // AI Financial Health & Category Breakdown Preview Card
                  _buildAiCategoryBreakdownCard(context, ref),
                  const SizedBox(height: 20),

                  // Cumulative expense line chart
                  chartAsync.when(
                    loading: () => const SkeletonBox(height: 280, borderRadius: 16),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (chart) => ExpenseChart(chart: chart),
                  ),
                  const SizedBox(height: 20),

                  // Spending summary bar charts (weekly / monthly)
                  const SpendingSummaryChart(),
                  const SizedBox(height: 24),

                  // Recent transactions header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.receipt_long_rounded,
                                size: 16, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Text('Recent Transactions',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  )),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go('/transactions');
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                        label: const Text('View All'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Recent transactions list
                  recentAsync.when(
                    loading: () => Column(
                      children: List.generate(3, (_) => const SkeletonTransactionTile()),
                    ),
                    error: (e, _) => AppErrorWidget(
                      error: e,
                      onRetry: () => ref.invalidate(recentTransactionsProvider),
                    ),
                    data: (txs) => txs.isEmpty
                        ? const _EmptyState()
                        : Column(
                            children: txs.map((tx) => TransactionCard(
                              transaction: tx,
                              onIgnoreToggle: null, // read-only on dashboard
                            )).toList(),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Expense breakdown comparison
                  budgetAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (budget) => _ExpenseComparisonCard(budget: budget),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _SyncFab(
        pollState: pollState,
        ref: ref,
        onSyncComplete: () {
          setState(() {
            _lastSyncedAt = DateTime.now();
          });
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      pinned: true,
      centerTitle: false,
      backgroundColor: AppColors.background,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.wallet_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Eric's Expense Tracker",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                ),
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_active_outlined, color: AppColors.primaryLight, size: 18),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showNtfyDialog(context);
          },
          tooltip: 'Notifikasi ntfy.sh',
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 18),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(authProvider.notifier).logout();
          },
          tooltip: 'Log Out',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showNtfyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: AppColors.primaryLight, size: 22),
              SizedBox(width: 10),
              Text(
                'Notifikasi ntfy.sh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Setiap transaksi BCA baru yang tercatat dari email otomatis dikirimkan ke ntfy.sh.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Topic Langganan:',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 4),
                    SelectableText(
                      'bca_expense_tracker_eric',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'URL: https://ntfy.sh/bca_expense_tracker_eric',
                      style: TextStyle(fontSize: 11, color: AppColors.textDisabled),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 14),
              label: const Text('Kirim Tes'),
              onPressed: () async {
                HapticFeedback.lightImpact();
                Navigator.pop(ctx);
                final sent = await NotificationService.triggerTestNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(sent
                          ? '🔔 Tes notifikasi terkirim ke ntfy.sh!'
                          : '⚠️ Gagal mengirim tes notifikasi'),
                      backgroundColor: sent ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAiCategoryBreakdownCard(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(categoryBreakdownProvider('month'));
    final aiSummaryAsync = ref.watch(aiSummaryProvider('month'));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.aiPurple.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.aiPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        size: 16, color: AppColors.aiPurple),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI & Kategori Pengeluaran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              aiSummaryAsync.maybeWhen(
                data: (resp) {
                  final (color, text) = switch (resp.ai.healthScore) {
                    'critical' => (AppColors.error, 'Waspada'),
                    'caution' => (AppColors.warning, 'Perhatian'),
                    _ => (AppColors.success, 'Sehat'),
                  };
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color, width: 0.8),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          breakdownAsync.when(
            loading: () => const AppSkeleton(height: 60, borderRadius: 10),
            error: (_, __) => const Text(
              'Buka detail breakdown untuk analisis lengkap.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            data: (data) {
              if (data.categories.isEmpty) {
                return const Text(
                  'Belum ada transaksi pada bulan ini.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                );
              }
              final topCategories = data.categories.take(3).toList();
              return Column(
                children: [
                  ...topCategories.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: c.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.categoryName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              '${c.percentage}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.compact(c.totalAmount),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              context.go('/breakdown');
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Lihat Detail Breakdown & AI Summary',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.primaryLight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSkeleton() {
    return const Column(
      children: [
        SkeletonBox(height: 128, borderRadius: 16),
        SizedBox(height: 12),
        SkeletonBox(height: 128, borderRadius: 16),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final String label;
  final BudgetPeriod period;
  final bool isFeatured;

  const _BudgetCard({
    required this.label,
    required this.period,
    this.isFeatured = false,
  });

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: period.isOverBudget
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        gradient: isFeatured
            ? LinearGradient(
                colors: [
                  AppColors.surface,
                  AppColors.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  if (isFeatured) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _progressColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _progressColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${period.percentUsed}%',
                  style: TextStyle(
                    color: _progressColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spent', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(period.realSpent),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _progressColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Budget Limit', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(period.budget),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: period.percentUsed / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(_progressColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                period.isOverBudget
                    ? 'Over budget by ${CurrencyFormatter.format(period.realSpent - period.budget)}'
                    : '${CurrencyFormatter.format(period.remaining)} remaining',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _progressColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (period.ignoredAmount > 0)
                Text(
                  'Ignored: ${CurrencyFormatter.compact(period.ignoredAmount)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textDisabled,
                  ),
                ),
            ],
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
          Text('Monthly Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 16),
          _ComparisonRow(
            label: 'Total Transactions',
            amount: budget.month.totalSpent,
            color: AppColors.textPrimary,
          ),
          const SizedBox(height: 10),
          _ComparisonRow(
            label: 'Actual Spent',
            subtitle: '(excluding ignored)',
            amount: budget.month.realSpent,
            color: AppColors.primary,
          ),
          if (budget.month.ignoredAmount > 0) ...[
            const SizedBox(height: 10),
            _ComparisonRow(
              label: 'Ignored Amount',
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _SyncFab extends StatelessWidget {
  final PollState pollState;
  final WidgetRef ref;
  final VoidCallback onSyncComplete;

  const _SyncFab({
    required this.pollState,
    required this.ref,
    required this.onSyncComplete,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: pollState.isPolling
          ? null
          : () async {
              HapticFeedback.mediumImpact();
              await ref.read(pollProvider.notifier).triggerPoll();
              final state = ref.read(pollProvider);
              if (!context.mounted) return;
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    backgroundColor: AppColors.error,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.lastMessage ?? 'Transaction sync completed'),
                    backgroundColor: AppColors.surfaceHighlight,
                  ),
                );
                ref.invalidate(budgetProvider);
                ref.invalidate(recentTransactionsProvider);
                ref.invalidate(budgetChartProvider);
                ref.invalidate(dailySummaryProvider);
                ref.invalidate(alertsProvider);
                ref.invalidate(dailyChartProvider);
                ref.invalidate(spendingSummaryProvider);
                onSyncComplete();
              }
            },
      backgroundColor: AppColors.primary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: pollState.isPolling
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : const Icon(Icons.sync_rounded, color: Colors.white),
      label: Text(
        pollState.isPolling ? 'Syncing...' : 'Sync BCA',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text('No Transactions Yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    )),
            const SizedBox(height: 4),
            Text('Tap the sync button below to fetch transactions from BCA emails',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// A transparent wrapper that adds a ripple tap gesture over its [child]
/// without affecting layout or visual appearance.
class _TappableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TappableCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                splashColor: AppColors.primary.withValues(alpha: 0.08),
                highlightColor: AppColors.primary.withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
