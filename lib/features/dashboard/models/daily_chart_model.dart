import 'package:expense_tracker/features/budget/models/budget_model.dart';

/// Information about an available week choice in a month.
class DailyChartWeekInfo {
  final int week;
  final String startDate;
  final String endDate;
  final int realSpent;

  const DailyChartWeekInfo({
    required this.week,
    required this.startDate,
    required this.endDate,
    required this.realSpent,
  });

  factory DailyChartWeekInfo.fromJson(Map<String, dynamic> json) {
    return DailyChartWeekInfo(
      week: (json['week'] as num?)?.toInt() ?? 1,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      realSpent: (json['realSpent'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Daily spending chart data model for a specific week returned by GET /api/budget/daily-chart.
class DailyChartModel {
  final int year;
  final int month;
  final int week;
  final String startDate;
  final String endDate;
  final int budget;
  final List<DailyChartWeekInfo> availableWeeks;
  final List<DailySpending> days;

  const DailyChartModel({
    required this.year,
    required this.month,
    required this.week,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.availableWeeks,
    required this.days,
  });

  factory DailyChartModel.fromJson(Map<String, dynamic> json) {
    final rawWeeks = json['availableWeeks'] as List?;
    final rawDays = json['days'] as List?;

    return DailyChartModel(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      week: (json['week'] as num?)?.toInt() ?? 1,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      budget: (json['budget'] as num?)?.toInt() ?? 0,
      availableWeeks: rawWeeks != null
          ? rawWeeks
              .whereType<Map<String, dynamic>>()
              .map((e) => DailyChartWeekInfo.fromJson(e))
              .toList()
          : const [],
      days: rawDays != null
          ? rawDays
              .whereType<Map<String, dynamic>>()
              .map((e) => DailySpending.fromJson(e))
              .toList()
          : const [],
    );
  }
}
