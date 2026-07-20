import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/features/dashboard/models/daily_summary_model.dart';

/// Fetches today's spending summary (WIB day) including top 5 most expensive
/// non-ignored transactions.
final dailySummaryProvider = FutureProvider<DailySummaryModel>((ref) async {
  final response = await ApiClient.instance.get(ApiEndpoints.budgetDailySummary);
  return DailySummaryModel.fromJson(response.data as Map<String, dynamic>);
});
