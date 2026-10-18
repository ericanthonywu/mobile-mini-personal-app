import 'package:expense_tracker/features/categories/models/category_model.dart';

/// Data model for a single split payment reimbursement on a transaction.
class SplitPaymentModel {
  final String id;
  final String transactionId;
  final int amount; // IDR integer, no decimals
  final String paidBy;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SplitPaymentModel({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.paidBy,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SplitPaymentModel.fromJson(Map<String, dynamic> json) {
    return SplitPaymentModel(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      amount: (json['amount'] as num).toInt(),
      paidBy: json['paid_by'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction_id': transactionId,
    'amount': amount,
    'paid_by': paidBy,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  SplitPaymentModel copyWith({
    int? amount,
    String? paidBy,
    String? notes,
  }) {
    return SplitPaymentModel(
      id: id,
      transactionId: transactionId,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Data model for a single transaction.
class TransactionModel {
  final String id;
  final int amount; // IDR integer, original amount recorded by BCA / manual entry
  final DateTime transactionDate; // WIB, stored without timezone
  final String merchant;
  final String transactionType;
  final String notes;
  final String? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final bool isIgnored;
  final String emailMessageId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Split payment fields
  final int totalSplitAmount; // Total reimbursed by others
  final int netAmount; // amount - totalSplitAmount (user's out-of-pocket expense)
  final List<SplitPaymentModel> splits;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.transactionDate,
    required this.merchant,
    required this.transactionType,
    required this.notes,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    required this.isIgnored,
    required this.emailMessageId,
    required this.createdAt,
    required this.updatedAt,
    this.totalSplitAmount = 0,
    int? netAmount,
    this.splits = const [],
  }) : netAmount = netAmount ?? amount;

  /// Original BCA amount recorded on e-statement (same as amount).
  int get originalAmount => amount;

  /// Whether this transaction has any split payments recorded.
  bool get hasSplits => splits.isNotEmpty;

  /// Returns a CategoryModel stub if category data is available inline.
  CategoryModel? get category {
    if (categoryId == null) return null;
    return CategoryModel(
      id: categoryId!,
      name: categoryName ?? 'Unknown',
      color: categoryColor ?? '#95A5A6',
      isDefault: false,
      createdAt: createdAt,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = (json['amount'] as num).toInt();
    final rawSplits = (json['splits'] as List?)
        ?.map((e) => SplitPaymentModel.fromJson(e as Map<String, dynamic>))
        .toList() ??
        const [];
    final splitTotal = (json['total_split_amount'] as num?)?.toInt() ??
        rawSplits.fold<int>(0, (sum, s) => sum + s.amount);
    final net = (json['net_amount'] as num?)?.toInt() ??
        (rawAmount - splitTotal).clamp(0, rawAmount);

    return TransactionModel(
      id: json['id'] as String,
      amount: rawAmount,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      merchant: json['merchant'] as String? ?? '',
      transactionType: json['transaction_type'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      categoryColor: json['category_color'] as String?,
      isIgnored: json['is_ignored'] as bool? ?? false,
      emailMessageId: json['email_message_id'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      totalSplitAmount: splitTotal,
      netAmount: net,
      splits: rawSplits,
    );
  }

  TransactionModel copyWith({
    int? amount,
    String? categoryId,
    String? categoryName,
    String? categoryColor,
    bool? isIgnored,
    bool clearCategory = false,
    int? totalSplitAmount,
    int? netAmount,
    List<SplitPaymentModel>? splits,
  }) {
    final nextAmount = amount ?? this.amount;
    final nextSplits = splits ?? this.splits;
    final nextSplitTotal = totalSplitAmount ??
        (splits != null
            ? nextSplits.fold<int>(0, (sum, s) => sum + s.amount)
            : this.totalSplitAmount);
    final nextNet = netAmount ??
        ((amount != null || splits != null || totalSplitAmount != null)
            ? (nextAmount - nextSplitTotal).clamp(0, nextAmount)
            : this.netAmount);

    return TransactionModel(
      id: id,
      amount: nextAmount,
      transactionDate: transactionDate,
      merchant: merchant,
      transactionType: transactionType,
      notes: notes,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      categoryColor: clearCategory ? null : (categoryColor ?? this.categoryColor),
      isIgnored: isIgnored ?? this.isIgnored,
      emailMessageId: emailMessageId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      totalSplitAmount: nextSplitTotal,
      netAmount: nextNet,
      splits: nextSplits,
    );
  }
}

/// Paginated list response for transactions.
class TransactionListResult {
  final List<TransactionModel> data;
  final int total;
  final int totalAmount;
  final int page;
  final int limit;
  final int totalPages;

  const TransactionListResult({
    required this.data,
    required this.total,
    required this.totalAmount,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory TransactionListResult.fromJson(Map<String, dynamic> json) {
    return TransactionListResult(
      data: (json['data'] as List)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      totalAmount: json['totalAmount'] as int? ?? 0,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
