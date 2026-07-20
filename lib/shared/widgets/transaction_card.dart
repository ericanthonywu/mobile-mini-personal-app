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

  /// Whether to render the notes line below the category/date row.
  /// Long notes are truncated to 2 lines with a tap-to-expand sheet.
  final bool showNotes;

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

  /// Called when the user chooses to permanently delete the transaction.
  /// If null, the delete action is not shown.
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.showIgnoreSlide = false,
    this.showNotes = false,
    this.onIgnoreToggle,
    this.onCategoryTap,
    this.onAmountTap,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);

    final hasIgnore = showIgnoreSlide && onIgnoreToggle != null;
    final hasDelete = onDelete != null;

    if (!hasIgnore && !hasDelete) {
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
          extentRatio: hasIgnore && hasDelete ? 0.5 : 0.28,
          children: [
            if (hasIgnore)
              SlidableAction(
                onPressed: (_) => onIgnoreToggle!(!transaction.isIgnored),
                backgroundColor: transaction.isIgnored ? AppColors.primary : AppColors.surfaceVariant,
                foregroundColor: transaction.isIgnored ? Colors.white : AppColors.textSecondary,
                icon: transaction.isIgnored ? Icons.visibility_rounded : Icons.visibility_off_outlined,
                label: transaction.isIgnored ? 'Restore' : 'Ignore',
                borderRadius: BorderRadius.circular(12),
              ),
            if (hasDelete)
              SlidableAction(
                onPressed: (_) => onDelete!(),
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
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
                        if (showNotes && transaction.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          GestureDetector(
                            onTap: () => _showNotesSheet(context),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.notes_rounded,
                                  size: 9,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    transaction.notes.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  void _showNotesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(sheetCtx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notes', style: Theme.of(sheetCtx).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(transaction.merchant, style: Theme.of(sheetCtx).textTheme.bodySmall),
            const SizedBox(height: 16),
            Text(
              transaction.notes.trim(),
              style: Theme.of(sheetCtx).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
