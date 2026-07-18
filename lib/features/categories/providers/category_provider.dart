import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/features/categories/models/category_model.dart';

/// Category list provider
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

  Future<void> create(String name, String color) async {
    try {
      await ApiClient.instance.post(ApiEndpoints.categories, data: {
        'name': name,
        'color': color,
      });
      await fetch();
    } catch (e) {
      throw extractApiError(e);
    }
  }

  Future<void> update(String id, {String? name, String? color}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (color != null) body['color'] = color;
      await ApiClient.instance.patch(ApiEndpoints.categoryById(id), data: body);
      await fetch();
    } catch (e) {
      throw extractApiError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await ApiClient.instance.delete(ApiEndpoints.categoryById(id));
      await fetch();
    } catch (e) {
      throw extractApiError(e);
    }
  }
}

/// Merchant rules provider
class MerchantRule {
  final String id;
  final String merchantPattern;
  final String categoryId;
  final String categoryName;
  final String categoryColor;

  const MerchantRule({
    required this.id,
    required this.merchantPattern,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  factory MerchantRule.fromJson(Map<String, dynamic> json) {
    return MerchantRule(
      id: json['id'] as String,
      merchantPattern: json['merchant_pattern'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      categoryColor: json['category_color'] as String,
    );
  }
}

final merchantRulesProvider =
    StateNotifierProvider<MerchantRuleNotifier, AsyncValue<List<MerchantRule>>>(
  (_) => MerchantRuleNotifier(),
);

class MerchantRuleNotifier extends StateNotifier<AsyncValue<List<MerchantRule>>> {
  MerchantRuleNotifier() : super(const AsyncLoading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncLoading();
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.merchantRules);
      final data = (response.data['data'] as List)
          .map((e) => MerchantRule.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncData(data);
    } catch (e) {
      state = AsyncError(extractApiError(e), StackTrace.current);
    }
  }

  Future<void> create(String pattern, String categoryId) async {
    try {
      await ApiClient.instance.post(ApiEndpoints.merchantRules, data: {
        'merchantPattern': pattern,
        'categoryId': categoryId,
      });
      await fetch();
    } catch (e) {
      throw extractApiError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await ApiClient.instance.delete(ApiEndpoints.merchantRuleById(id));
      await fetch();
    } catch (e) {
      throw extractApiError(e);
    }
  }
}
