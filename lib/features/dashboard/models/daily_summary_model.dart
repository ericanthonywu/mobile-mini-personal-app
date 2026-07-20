import 'package:flutter/material.dart';

/// A single transaction entry in the daily summary top-5 list.
class TopTransaction {
  final String id;
  final String merchant;
  final int amount;
  final DateTime transactionDate;
  final String notes;
  final String? categoryName;
  final String? categoryColor;

  const TopTransaction({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.transactionDate,
    required this.notes,
    this.categoryName,
    this.categoryColor,
  });

  /// Parses the hex categoryColor string into a Flutter Color, if available.
  Color? get categoryColorValue {
    final hex = categoryColor?.replaceAll('#', '');
    if (hex == null || hex.length != 6) return null;
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory TopTransaction.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['transactionDate'] != null
          ? DateTime.parse(json['transactionDate'] as String)
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return TopTransaction(
      id: json['id'] as String? ?? '',
      merchant: json['merchant'] as String? ?? 'Unknown Merchant',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      transactionDate: parsedDate,
      notes: json['notes'] as String? ?? '',
      categoryName: json['categoryName'] as String?,
      categoryColor: json['categoryColor'] as String?,
    );
  }
}

/// Model for the daily spending summary returned by GET /api/budget/daily-summary.
class DailySummaryModel {
  /// The date this summary covers (YYYY-MM-DD, WIB).
  final String date;

  /// Total spending including ignored transactions.
  final int totalSpent;

  /// Spending excluding ignored transactions (matches budget tracking).
  final int realSpent;

  /// Up to 5 most expensive non-ignored transactions today, sorted desc.
  final List<TopTransaction> topTransactions;

  const DailySummaryModel({
    required this.date,
    required this.totalSpent,
    required this.realSpent,
    required this.topTransactions,
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['topTransactions'] as List?;
    return DailySummaryModel(
      date: json['date'] as String? ?? '',
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      realSpent: (json['realSpent'] as num?)?.toInt() ?? 0,
      topTransactions: rawList != null
          ? rawList
              .whereType<Map<String, dynamic>>()
              .map((e) => TopTransaction.fromJson(e))
              .toList()
          : const [],
    );
  }
}
