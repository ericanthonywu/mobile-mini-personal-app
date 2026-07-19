import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/features/dashboard/models/alert_model.dart';

/// Fetches all unresolved parse-failure alerts from the backend.
///
/// Errors are silently absorbed by the dashboard — alerts are informational,
/// not critical, so a failing fetch should never break the dashboard.
final alertsProvider = FutureProvider<List<AlertModel>>((ref) async {
  final response = await ApiClient.instance.get(ApiEndpoints.alerts);
  final list = (response.data['data'] as List)
      .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
      .toList();
  return list;
});
