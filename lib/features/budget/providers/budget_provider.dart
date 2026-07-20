import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/core/utils/widget_service.dart';
import 'package:expense_tracker/features/budget/models/budget_model.dart';

final budgetProvider = FutureProvider<BudgetSummaryModel>((ref) async {
  final response = await ApiClient.instance.get(ApiEndpoints.budget);
  final map = response.data as Map<String, dynamic>;
  await WidgetService.saveBudgetSummary(map);
  return BudgetSummaryModel.fromJson(map);
});

/// Chart data for weekly/monthly expense graphs
final budgetChartProvider = FutureProvider<BudgetChartModel>((ref) async {
  final response = await ApiClient.instance.get(ApiEndpoints.budgetChart);
  return BudgetChartModel.fromJson(response.data as Map<String, dynamic>);
});

/// Poll state for manual sync button
class PollState {
  final bool isPolling;
  final String? lastMessage;
  final String? error;

  const PollState({
    this.isPolling = false,
    this.lastMessage,
    this.error,
  });

  PollState copyWith({bool? isPolling, String? lastMessage, String? error}) {
    return PollState(
      isPolling: isPolling ?? this.isPolling,
      lastMessage: lastMessage ?? this.lastMessage,
      error: error,
    );
  }
}

class PollNotifier extends StateNotifier<PollState> {
  PollNotifier() : super(const PollState());

  Future<void> triggerPoll() async {
    if (state.isPolling) return;
    state = state.copyWith(isPolling: true, error: null);
    try {
      final response = await ApiClient.instance.post(ApiEndpoints.poll);
      final message = response.data['message'] as String;
      state = state.copyWith(isPolling: false, lastMessage: message);
      // Refresh the home screen widget with latest budget data
      await WidgetService.refreshWidget();
    } catch (e) {
      state = state.copyWith(isPolling: false, error: extractApiError(e));
    }
  }
}

final pollProvider = StateNotifierProvider<PollNotifier, PollState>(
  (_) => PollNotifier(),
);
