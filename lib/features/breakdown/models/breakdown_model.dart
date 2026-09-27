import 'package:flutter/material.dart';

class CategoryBreakdownItem {
  final String? categoryId;
  final String categoryName;
  final Color color;
  final int transactionCount;
  final int totalAmount;
  final int averageAmount;
  final double percentage;

  const CategoryBreakdownItem({
    this.categoryId,
    required this.categoryName,
    required this.color,
    required this.transactionCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.percentage,
  });

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json) {
    Color parsedColor = const Color(0xFF94A3B8);
    final rawColor = json['categoryColor'] as String?;
    if (rawColor != null && rawColor.isNotEmpty) {
      try {
        final hex = rawColor.replaceAll('#', '');
        if (hex.length == 6) {
          parsedColor = Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          parsedColor = Color(int.parse(hex, radix: 16));
        }
      } catch (_) {}
    }

    return CategoryBreakdownItem(
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String? ?? 'Tanpa Kategori',
      color: parsedColor,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      averageAmount: (json['averageAmount'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TopMerchantItem {
  final String merchant;
  final int totalSpent;
  final int count;

  const TopMerchantItem({
    required this.merchant,
    required this.totalSpent,
    required this.count,
  });

  factory TopMerchantItem.fromJson(Map<String, dynamic> json) {
    return TopMerchantItem(
      merchant: json['merchant'] as String? ?? '-',
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CategoryBreakdownResponse {
  final String period;
  final String label;
  final int totalSpent;
  final int totalCount;
  final int uncategorizedCount;
  final int uncategorizedSpent;
  final List<CategoryBreakdownItem> categories;
  final List<TopMerchantItem> topMerchants;

  const CategoryBreakdownResponse({
    required this.period,
    required this.label,
    required this.totalSpent,
    required this.totalCount,
    required this.uncategorizedCount,
    required this.uncategorizedSpent,
    required this.categories,
    required this.topMerchants,
  });

  factory CategoryBreakdownResponse.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'] as List<dynamic>? ?? [];
    final rawMerchants = json['topMerchants'] as List<dynamic>? ?? [];

    return CategoryBreakdownResponse(
      period: json['period'] as String? ?? 'month',
      label: json['label'] as String? ?? 'Bulan Ini',
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      uncategorizedCount: (json['uncategorizedCount'] as num?)?.toInt() ?? 0,
      uncategorizedSpent: (json['uncategorizedSpent'] as num?)?.toInt() ?? 0,
      categories: rawCategories
          .map((c) => CategoryBreakdownItem.fromJson(c as Map<String, dynamic>))
          .toList(),
      topMerchants: rawMerchants
          .map((m) => TopMerchantItem.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
