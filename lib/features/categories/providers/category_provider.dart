import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/features/categories/models/category_model.dart';

/// Category list provider used for transaction category selection and filtering
final categoriesProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<List<CategoryModel>>>(
  (_) => CategoryNotifier(),
);

class CategoryNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  CategoryNotifier() : super(const AsyncLoading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.categories);
      final data = (response.data['data'] as List)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(extractApiError(e), StackTrace.current);
    }
  }
}
