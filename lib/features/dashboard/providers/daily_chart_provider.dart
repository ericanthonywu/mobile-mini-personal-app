import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/features/dashboard/models/daily_chart_model.dart';

class DailyChartParams {
  final int year;
  final int month;
  final int? week;

  const DailyChartParams({
    required this.year,
    required this.month,
    this.week,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyChartParams &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          week == other.week;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ week.hashCode;
}

final dailyChartProvider =
    FutureProvider.family<DailyChartModel, DailyChartParams>((ref, params) async {
  final queryMap = <String, dynamic>{
    'year': params.year,
    'month': params.month,
  };
  if (params.week != null) {
    queryMap['week'] = params.week;
  }

  final response = await ApiClient.instance.get(
    ApiEndpoints.budgetDailyChart,
    queryParameters: queryMap,
  );

  return DailyChartModel.fromJson(response.data as Map<String, dynamic>);
});
