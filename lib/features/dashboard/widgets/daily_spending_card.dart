import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/dashboard/models/daily_summary_model.dart';
import 'package:expense_tracker/features/dashboard/providers/daily_summary_provider.dart';

/// Premium card showing today's (WIB) total spending and the top 5 most
/// expensive transactions, with staggered animation on load.
class DailySpendingCard extends ConsumerWidget {
  const DailySpendingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailySummaryProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: async.when(
        loading: () => _buildSkeleton(),
        error: (_, __) => const SizedBox.shrink(), // silently skip if fails
        data: (summary) => _buildContent(context, summary),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 14, width: 120, decoration: BoxDecoration(
            color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 12),
          Container(height: 28, width: 180, decoration: BoxDecoration(
            color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(height: 44, decoration: BoxDecoration(
              color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8))),
          )),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DailySummaryModel summary) {
    // Parse today's date label
    final dateParts = summary.date.split('-');
    String dateLabel = 'Today';
    if (dateParts.length == 3) {
      final dt = DateTime.tryParse(summary.date);
      if (dt != null) dateLabel = DateFormatter.date(dt);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Spending",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Total amount chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: summary.realSpent > 0
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: summary.realSpent > 0
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  CurrencyFormatter.compact(summary.realSpent),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: summary.realSpent > 0
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          // ── Empty state ───────────────────────────────────────────────────
          if (summary.topTransactions.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 36,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No spending today',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            // ── Divider + section label ───────────────────────────────────
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, size: 12, color: AppColors.textDisabled),
                const SizedBox(width: 4),
                Text(
                  'Top ${summary.topTransactions.length} transactions',
                  style: const TextStyle(fontSize: 10, color: AppColors.textDisabled),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Transaction list ──────────────────────────────────────────
            ...summary.topTransactions.asMap().entries.map((entry) {
              return _TopTransactionTile(
                rank: entry.key + 1,
                tx: entry.value,
                isLast: entry.key == summary.topTransactions.length - 1,
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _TopTransactionTile extends StatelessWidget {
  final int rank;
  final TopTransaction tx;
  final bool isLast;

  const _TopTransactionTile({
    required this.rank,
    required this.tx,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = tx.categoryColorValue ?? AppColors.textDisabled;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _rankColor(rank).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _rankColor(rank),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Category dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),

          // Merchant + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchant,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormatter.relativeWithTime(tx.transactionDate),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            CurrencyFormatter.format(tx.amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // gold
      case 2:
        return const Color(0xFFC0C0C0); // silver
      case 3:
        return const Color(0xFFCD7F32); // bronze
      default:
        return AppColors.textDisabled;
    }
  }
}
