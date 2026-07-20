import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:expense_tracker/core/theme/app_colors.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';

/// Reusable transaction card widget.
/// Used in both the Dashboard (read-only) and Transactions list (interactive).
class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final bool showIgnoreSlide;

  /// Called when the user toggles the ignored status.
  /// If null, the ignore action is not shown.
  final void Function(bool isIgnored)? onIgnoreToggle;

  /// Called when the user taps the category area.
  /// If null, category is not tappable.
  final VoidCallback? onCategoryTap;

  /// Called when the user taps the amount.
  /// If null, amount is not tappable.
  final VoidCallback? onAmountTap;

  /// Called when the user taps anywhere on the card.
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.showIgnoreSlide = false,
    this.onIgnoreToggle,
    this.onCategoryTap,
    this.onAmountTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);

    if (!showIgnoreSlide || onIgnoreToggle == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: card,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: ValueKey(transaction.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.28,
          children: [
            SlidableAction(
              onPressed: (_) => onIgnoreToggle!(!transaction.isIgnored),
              backgroundColor: transaction.isIgnored ? AppColors.primary : AppColors.surfaceVariant,
              foregroundColor: transaction.isIgnored ? Colors.white : AppColors.textSecondary,
              icon: transaction.isIgnored ? Icons.visibility_rounded : Icons.visibility_off_outlined,
              label: transaction.isIgnored ? 'Restore' : 'Ignore',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: card,
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final category = transaction.category;
    final isIgnored = transaction.isIgnored;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isIgnored ? 0.55 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isIgnored ? AppColors.border.withOpacity(0.5) : AppColors.border,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Category color indicator
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (category?.colorValue ?? AppColors.textDisabled).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: category?.colorValue ?? AppColors.textDisabled,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.merchant,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: isIgnored ? TextDecoration.lineThrough : null,
                            color: isIgnored ? AppColors.textSecondary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            // Category chip
                            GestureDetector(
                              onTap: onCategoryTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (category?.colorValue ?? AppColors.textDisabled).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category?.name ?? 'Uncategorized',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: category?.colorValue ?? AppColors.textDisabled,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormatter.relativeWithTime(transaction.transactionDate),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount
                  GestureDetector(
                    onTap: onAmountTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(transaction.amount),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isIgnored ? AppColors.textSecondary : AppColors.textPrimary,
                            decoration: isIgnored ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (isIgnored)
                          const Text(
                            'Ignored',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: AppColors.textDisabled,
                            ),
                          ),
                        if (onAmountTap != null && !isIgnored)
                          const Text(
                            'Edit',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
