/// Model for a single entry in the spending summary (one week or one month).
class SpendingEntry {
  /// Week number (1-5) when mode is 'week', month number (1-12) when mode is 'month'.
  final int index;
  final int realSpent;
  final int totalSpent;
  /// Only present when mode == 'week'. ISO date string e.g. "2026-07-27".
  final String? startDate;
  /// Only present when mode == 'week'. ISO date string e.g. "2026-08-02".
  final String? endDate;

  const SpendingEntry({
    required this.index,
    required this.realSpent,
    required this.totalSpent,
    this.startDate,
    this.endDate,
  });

  factory SpendingEntry.fromJson(Map<String, dynamic> json, String mode) {
    final rawIndex = json[mode == 'week' ? 'week' : 'month'] as num?;
    return SpendingEntry(
      index: rawIndex?.toInt() ?? 1,
      realSpent: (json['realSpent'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
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
    final mode = json['mode'] as String? ?? 'week';
    final rawEntries = json['entries'] as List?;
    return SpendingSummaryModel(
      mode: mode,
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt(),
      budget: (json['budget'] as num?)?.toInt() ?? 0,
      entries: rawEntries != null
          ? rawEntries
              .whereType<Map<String, dynamic>>()
              .map((e) => SpendingEntry.fromJson(e, mode))
              .toList()
          : const [],
    );
  }
}
