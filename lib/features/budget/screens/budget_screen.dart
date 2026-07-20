import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/budget/providers/budget_provider.dart';
import 'package:expense_tracker/features/budget/models/budget_model.dart';
import 'package:expense_tracker/shared/widgets/app_skeleton.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final budgetAsync = ref.watch(budgetProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(budgetProvider);
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text('Budget Analysis', style: Theme.of(context).textTheme.headlineSmall),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                onPressed: () => ref.invalidate(budgetProvider),
                tooltip: 'Refresh',
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: budgetAsync.when(
              loading: () => SliverList(
                delegate: SliverChildListDelegate([
                  const _SectionHeader(title: 'This Week', subtitle: 'Loading...'),
                  const SizedBox(height: 12),
                  const SkeletonBudgetRingCard(),
                  const SizedBox(height: 20),
                  const _SectionHeader(title: 'This Month', subtitle: 'Loading...'),
                  const SizedBox(height: 12),
                  const SkeletonBudgetRingCard(),
                  const SizedBox(height: 20),
                  const SkeletonBox(height: 180, borderRadius: 16),
                  const SizedBox(height: 20),
                  const SkeletonStatGrid(),
                ]),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(e.toString(), style: const TextStyle(color: AppColors.error)),
                      TextButton(
                        onPressed: () => ref.refresh(budgetProvider),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (budget) => SliverList(
                delegate: SliverChildListDelegate([
                  // Weekly section
                  _SectionHeader(title: 'This Week', subtitle: '${DateFormatter.short(budget.week.start)} – ${DateFormatter.short(budget.week.end)}'),
                  const SizedBox(height: 12),
                  _BudgetRingCard(period: budget.week, label: 'Weekly'),
                  const SizedBox(height: 20),

                  // Monthly section
                  _SectionHeader(title: 'This Month', subtitle: DateFormatter.monthYear(budget.month.start)),
                  const SizedBox(height: 12),
                  _BudgetRingCard(period: budget.month, label: 'Monthly'),
                  const SizedBox(height: 20),

                  // Real vs Total breakdown
                  _ComparisonBarCard(
                    label: 'Actual vs Total Spending Breakdown',
                    realSpent: budget.month.realSpent,
                    totalSpent: budget.month.totalSpent,
                    budget: budget.month.budget,
                  ),
                  const SizedBox(height: 20),

                  // Summary stats
                  _StatsGrid(budget: budget),
                ]),
              ),
            ),
          ),
        ],
        ),  // CustomScrollView
      ),    // RefreshIndicator
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _BudgetRingCard extends StatelessWidget {
  final BudgetPeriod period;
  final String label;

  const _BudgetRingCard({required this.period, required this.label});

  Color get _color {
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
      child: Row(
        children: [
          // Ring chart
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: period.percentUsed / 100),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 0,
                      centerSpaceRadius: 34,
                      sections: [
                        PieChartSectionData(
                          value: value * 100,
                          color: _color,
                          radius: 12,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: (1 - value).clamp(0, 1) * 100,
                          color: AppColors.surfaceVariant,
                          radius: 12,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  '${period.percentUsed}%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Breakdown details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  label: 'Spent',
                  value: CurrencyFormatter.format(period.realSpent),
                  color: _color,
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: 'Budget',
                  value: CurrencyFormatter.format(period.budget),
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: period.isOverBudget ? 'Over Budget' : 'Remaining',
                  value: CurrencyFormatter.format(
                    period.isOverBudget ? (period.realSpent - period.budget) : period.remaining,
                  ),
                  color: _color,
                ),
                if (period.ignoredAmount > 0) ...[
                  const SizedBox(height: 8),
                  _StatRow(
                    label: 'Ignored',
                    value: CurrencyFormatter.format(period.ignoredAmount),
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            )),
      ],
    );
  }
}

class _ComparisonBarCard extends StatelessWidget {
  final String label;
  final int realSpent;
  final int totalSpent;
  final int budget;

  const _ComparisonBarCard({
    required this.label,
    required this.realSpent,
    required this.totalSpent,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = [realSpent, totalSpent, budget].reduce((a, b) => a > b ? a : b).toDouble();

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
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final labels = ['Actual', 'Total', 'Budget'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[value.toInt()],
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontFamily: 'Inter',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildBar(0, realSpent.toDouble(), AppColors.primary, maxVal),
                  _buildBar(1, totalSpent.toDouble(), AppColors.secondary.withOpacity(0.7), maxVal),
                  _buildBar(2, budget.toDouble(), AppColors.border, maxVal),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double value, Color color, double maxVal) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: color,
          width: 40,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxVal * 1.2,
            color: AppColors.surfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final BudgetSummaryModel budget;

  const _StatsGrid({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(
              title: 'Weekly Remaining',
              value: CurrencyFormatter.format(budget.week.remaining),
              icon: Icons.calendar_view_week_rounded,
              color: budget.week.isOverBudget ? AppColors.error : AppColors.success,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              title: 'Monthly Remaining',
              value: CurrencyFormatter.format(budget.month.remaining),
              icon: Icons.calendar_month_rounded,
              color: budget.month.isOverBudget ? AppColors.error : AppColors.success,
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatCard(
              title: 'Total Ignored',
              value: CurrencyFormatter.format(budget.month.ignoredAmount),
              icon: Icons.visibility_off_outlined,
              color: AppColors.textSecondary,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              title: 'Monthly Usage',
              value: '${budget.month.percentUsed}%',
              icon: Icons.donut_small_rounded,
              color: budget.month.isOverBudget ? AppColors.error
                  : budget.month.percentUsed >= 80 ? AppColors.warning
                  : AppColors.primary,
            )),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              )),
          const SizedBox(height: 2),
          Text(title, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
