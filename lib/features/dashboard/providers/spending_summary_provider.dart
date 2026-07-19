import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/features/budget/models/spending_summary_model.dart';

/// Parameters for the spending summary provider.
class SpendingSummaryParams {
  final String mode; // 'week' | 'month'
  final int year;
  final int? month; // required when mode == 'week'

  const SpendingSummaryParams({
    required this.mode,
    required this.year,
    this.month,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpendingSummaryParams &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => Object.hash(mode, year, month);
}

final spendingSummaryProvider =
    FutureProvider.family<SpendingSummaryModel, SpendingSummaryParams>(
  (ref, params) async {
    final queryParams = <String, String>{
      'mode': params.mode,
      'year': params.year.toString(),
    };
    if (params.month != null) {
      queryParams['month'] = params.month.toString();
    }

    final response = await ApiClient.instance.get(
      ApiEndpoints.budgetSpendingSummary,
      queryParameters: queryParams,
    );
    return SpendingSummaryModel.fromJson(
        response.data as Map<String, dynamic>);
  },
);
