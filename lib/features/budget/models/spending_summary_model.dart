/// Model for a single entry in the spending summary (one week or one month).
class SpendingEntry {
  /// Week number (1-5) when mode is 'week', month number (1-12) when mode is 'month'.
  final int index;
  final int realSpent;
  final int totalSpent;

  const SpendingEntry({
    required this.index,
    required this.realSpent,
    required this.totalSpent,
  });

  factory SpendingEntry.fromJson(Map<String, dynamic> json, String mode) {
    return SpendingEntry(
      index: (json[mode == 'week' ? 'week' : 'month'] as num).toInt(),
      realSpent: (json['realSpent'] as num).toInt(),
      totalSpent: (json['totalSpent'] as num).toInt(),
    );
  }
}

/// Full spending summary returned by GET /api/budget/spending-summary
class SpendingSummaryModel {
  final String mode; // 'week' | 'month'
  final int year;
  final int? month; // only when mode == 'week'
  final int budget;
  final List<SpendingEntry> entries;

  const SpendingSummaryModel({
    required this.mode,
    required this.year,
    this.month,
    required this.budget,
    required this.entries,
  });

  factory SpendingSummaryModel.fromJson(Map<String, dynamic> json) {
    final mode = json['mode'] as String;
    return SpendingSummaryModel(
      mode: mode,
      year: (json['year'] as num).toInt(),
      month: json['month'] != null ? (json['month'] as num).toInt() : null,
      budget: (json['budget'] as num).toInt(),
      entries: (json['entries'] as List)
          .map((e) => SpendingEntry.fromJson(e as Map<String, dynamic>, mode))
          .toList(),
    );
  }
}
