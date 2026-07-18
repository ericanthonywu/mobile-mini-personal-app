import 'package:dio/dio.dart';
import 'package:expense_tracker/core/config/app_config.dart';
import 'package:expense_tracker/core/storage/secure_storage.dart';

/// Singleton Dio HTTP client with JWT interceptor.
/// All API calls must go through this client.
class ApiClient {
  ApiClient._();

  static final Dio _dio = _buildDio();

  static Dio get instance => _dio;

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // JWT interceptor — automatically attaches token to every request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Surface clean API errors to the UI
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}

/// Extracts a user-friendly error message from a Dio error.
String extractApiError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data.containsKey('error')) {
      return data['error'].toString();
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please try again.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Check that the backend is running.';
    }
  }
  return 'An unexpected error occurred.';
}
