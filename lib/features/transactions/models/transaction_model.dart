import 'package:expense_tracker/features/categories/models/category_model.dart';

/// Data model for a single transaction.
class TransactionModel {
  final String id;
  final int amount; // IDR integer, no decimals
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
  });

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
    return TransactionModel(
      id: json['id'] as String,
      amount: json['amount'] as int,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      merchant: json['merchant'] as String,
      transactionType: json['transaction_type'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      categoryColor: json['category_color'] as String?,
      isIgnored: json['is_ignored'] as bool? ?? false,
      emailMessageId: json['email_message_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  TransactionModel copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryColor,
    bool? isIgnored,
  }) {
    return TransactionModel(
      id: id,
      amount: amount,
      transactionDate: transactionDate,
      merchant: merchant,
      transactionType: transactionType,
      notes: notes,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      isIgnored: isIgnored ?? this.isIgnored,
      emailMessageId: emailMessageId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Paginated list response for transactions.
class TransactionListResult {
  final List<TransactionModel> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const TransactionListResult({
    required this.data,
    required this.total,
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
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
