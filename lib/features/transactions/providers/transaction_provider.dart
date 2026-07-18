import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';

/// Filters for the transaction list
class TransactionFilters {
  final String? categoryId;
  final bool? isIgnored;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? search;
  final int page;
  final int limit;

  const TransactionFilters({
    this.categoryId,
    this.isIgnored,
    this.dateFrom,
    this.dateTo,
    this.search,
    this.page = 1,
    this.limit = 20,
  });

  TransactionFilters copyWith({
    String? categoryId,
    bool? isIgnored,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
    int? page,
    int? limit,
    bool clearCategory = false,
    bool clearIgnored = false,
    bool clearSearch = false,
  }) {
    return TransactionFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      isIgnored: clearIgnored ? null : (isIgnored ?? this.isIgnored),
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      search: clearSearch ? null : (search ?? this.search),
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (categoryId != null) 'categoryId': categoryId,
      if (isIgnored != null) 'isIgnored': isIgnored.toString(),
      if (dateFrom != null) 'dateFrom': dateFrom!.toIso8601String(),
      if (dateTo != null) 'dateTo': dateTo!.toIso8601String(),
      if (search != null && search!.isNotEmpty) 'search': search,
      'page': page.toString(),
      'limit': limit.toString(),
    };
  }
}

/// Transaction list state
class TransactionListState {
  final List<TransactionModel> transactions;
  final int total;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final TransactionFilters filters;

  const TransactionListState({
    this.transactions = const [],
    this.total = 0,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.filters = const TransactionFilters(),
  });

  TransactionListState copyWith({
    List<TransactionModel>? transactions,
    int? total,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    TransactionFilters? filters,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      filters: filters ?? this.filters,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionListState> {
  TransactionNotifier() : super(const TransactionListState()) {
    fetch();
  }

  Future<void> fetch({bool reset = true}) async {
    if (reset) {
      state = state.copyWith(isLoading: true, error: null, filters: state.filters.copyWith(page: 1));
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final response = await ApiClient.instance.get(
        ApiEndpoints.transactions,
        queryParameters: state.filters.toQueryParams(),
      );
      final result = TransactionListResult.fromJson(
        response.data as Map<String, dynamic>,
      );

      state = state.copyWith(
        transactions: reset
            ? result.data
            : [...state.transactions, ...result.data],
        total: result.total,
        totalPages: result.totalPages,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: extractApiError(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.filters.page >= state.totalPages || state.isLoadingMore) return;
    state = state.copyWith(filters: state.filters.copyWith(page: state.filters.page + 1));
    await fetch(reset: false);
  }

  void applyFilters(TransactionFilters filters) {
    state = state.copyWith(filters: filters);
    fetch();
  }

  /// Updates a transaction in-place (for ignore toggle / category change / amount edit)
  Future<void> updateTransaction(
    String id, {
    String? categoryId,
    String? categoryName,
    String? categoryColor,
    bool clearCategory = false,
    bool? isIgnored,
    int? amount,
  }) async {
    try {
      final body = <String, dynamic>{};
      // clearCategory explicitly sends null to API to remove the category
      if (clearCategory) {
        body['categoryId'] = null;
      } else if (categoryId != null) {
        body['categoryId'] = categoryId;
      }
      if (isIgnored != null) body['isIgnored'] = isIgnored;
      if (amount != null) body['amount'] = amount;

      await ApiClient.instance.patch(
        ApiEndpoints.transactionById(id),
        data: body,
      );

      // Update locally for immediate, correct UI feedback
      final updated = state.transactions.map((tx) {
        if (tx.id != id) return tx;
        return tx.copyWith(
          isIgnored: isIgnored ?? tx.isIgnored,
          categoryId: categoryId,
          categoryName: categoryName,
          categoryColor: categoryColor,
          clearCategory: clearCategory,
          amount: amount ?? tx.amount,
        );
      }).toList();

      state = state.copyWith(transactions: updated);
    } catch (e) {
      state = state.copyWith(error: extractApiError(e));
    }
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionListState>(
  (_) => TransactionNotifier(),
);

/// Recent transactions for dashboard
final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final response = await ApiClient.instance.get(
    ApiEndpoints.transactionsRecent,
    queryParameters: {'limit': '5'},
  );
  final data = (response.data['data'] as List)
      .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
      .toList();
  return data;
});
