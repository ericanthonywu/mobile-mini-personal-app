import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/features/breakdown/models/breakdown_model.dart';
import 'package:expense_tracker/features/breakdown/models/ai_summary_model.dart';
import 'package:expense_tracker/features/transactions/providers/transaction_provider.dart';

/// Currently selected breakdown period:
/// 'week', 'month', 'last_month', '3_months', 'all'
final selectedBreakdownPeriodProvider = StateProvider<String>((ref) => 'month');

/// Fetches category breakdown data based on period
final categoryBreakdownProvider =
    FutureProvider.family<CategoryBreakdownResponse, String>(
        (ref, period) async {
  final response = await ApiClient.instance.get(
    ApiEndpoints.categoryBreakdown,
    queryParameters: {'period': period},
  );
  return CategoryBreakdownResponse.fromJson(
      response.data as Map<String, dynamic>);
});

/// Fetches AI-powered summary for the selected period
final aiSummaryProvider =
    FutureProvider.family<AiExpenseSummaryResponse, String>(
        (ref, period) async {
  final response = await ApiClient.instance.get(
    ApiEndpoints.aiSummary,
    queryParameters: {'period': period},
  );
  return AiExpenseSummaryResponse.fromJson(
      response.data as Map<String, dynamic>);
});

/// State for AI Categorization Actions
class AiCategorizationState {
  final bool isCategorizing;
  final String? successMessage;
  final String? errorMessage;

  const AiCategorizationState({
    this.isCategorizing = false,
    this.successMessage,
    this.errorMessage,
  });

  AiCategorizationState copyWith({
    bool? isCategorizing,
    String? successMessage,
    String? errorMessage,
  }) {
    return AiCategorizationState(
      isCategorizing: isCategorizing ?? this.isCategorizing,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

class AiCategorizationNotifier extends StateNotifier<AiCategorizationState> {
  final Ref _ref;
  AiCategorizationNotifier(this._ref) : super(const AiCategorizationState());

  /// Categorize all uncategorized transactions with Gemini AI
  Future<int> categorizeAll() async {
    state = state.copyWith(isCategorizing: true, errorMessage: null);
    try {
      final response =
          await ApiClient.instance.post(ApiEndpoints.aiCategorizeAll);
      final data = response.data as Map<String, dynamic>;
      final categorizedCount = (data['categorized'] as num?)?.toInt() ?? 0;
      final totalProcessed = (data['processed'] as num?)?.toInt() ?? 0;

      state = state.copyWith(
        isCategorizing: false,
        successMessage: totalProcessed == 0
            ? 'Semua transaksi sudah memiliki kategori.'
            : 'Berhasil mengkategorikan $categorizedCount dari $totalProcessed transaksi.',
      );

      // Invalidate relevant providers to refresh the UI immediately
      final currentPeriod = _ref.read(selectedBreakdownPeriodProvider);
      _ref.invalidate(categoryBreakdownProvider(currentPeriod));
      _ref.invalidate(aiSummaryProvider(currentPeriod));
      _ref.read(transactionProvider.notifier).fetch();

      return categorizedCount;
    } catch (e) {
      state = state.copyWith(
        isCategorizing: false,
        errorMessage: extractApiError(e),
      );
      return 0;
    }
  }

  /// Categorize a single transaction by ID
  Future<bool> categorizeSingle(String transactionId) async {
    state = state.copyWith(isCategorizing: true, errorMessage: null);
    try {
      final response = await ApiClient.instance
          .post(ApiEndpoints.aiCategorize(transactionId));
      final data = response.data as Map<String, dynamic>;
      final ai = data['ai'] as Map<String, dynamic>?;
      final categoryName = ai?['categoryName'] as String?;

      state = state.copyWith(
        isCategorizing: false,
        successMessage: categoryName != null
            ? 'Kategori diatur ke: $categoryName'
            : 'Transaksi berhasil dianalisis.',
      );

      final currentPeriod = _ref.read(selectedBreakdownPeriodProvider);
      _ref.invalidate(categoryBreakdownProvider(currentPeriod));
      _ref.read(transactionProvider.notifier).fetch();
      return true;
    } catch (e) {
      state = state.copyWith(
        isCategorizing: false,
        errorMessage: extractApiError(e),
      );
      return false;
    }
  }
}

final aiCategorizationProvider =
    StateNotifierProvider<AiCategorizationNotifier, AiCategorizationState>(
  (ref) => AiCategorizationNotifier(ref),
);
