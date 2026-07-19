import 'dart:async';
import 'package:dio/dio.dart';
import 'package:expense_tracker/core/config/app_config.dart';
import 'package:expense_tracker/core/storage/secure_storage.dart';

// ---------------------------------------------------------------------------
// Structured error types — lets UI render contextual icons + messages
// ---------------------------------------------------------------------------

enum ApiErrorType {
  connection, // no network / can't reach server
  timeout, // connect or receive timeout
  serverError, // 5xx from server
  clientError, // 4xx from server
  unknown,
}

class ApiError {
  final ApiErrorType type;
  final String message;
  const ApiError(this.type, this.message);
}

// ---------------------------------------------------------------------------
// Retry interceptor — retries network-level failures on idempotent methods
// ---------------------------------------------------------------------------

class _RetryInterceptor extends Interceptor {
  static const int _maxRetries = 3;
  static const Set<String> _idempotentMethods = {'GET', 'HEAD', 'OPTIONS'};

  final Dio _dio;
  _RetryInterceptor(this._dio);

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final method = err.requestOptions.method.toUpperCase();

    // Only retry idempotent methods to avoid duplicate side effects
    if (!_idempotentMethods.contains(method)) {
      return handler.next(err);
    }

    // Only retry on network-level failures — NOT on 4xx/5xx HTTP errors
    final isRetryable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.sendTimeout;

    if (!isRetryable) {
      return handler.next(err);
    }

    final attempt = (err.requestOptions.extra['_retryAttempt'] as int?) ?? 0;
    if (attempt >= _maxRetries) {
      return handler.next(err);
    }

    // Exponential backoff: 1s → 2s → 4s
    final delaySeconds = 1 << attempt; // 1, 2, 4
    await Future.delayed(Duration(seconds: delaySeconds));

    // Clone request options with incremented attempt counter
    final options = err.requestOptions;
    options.extra['_retryAttempt'] = attempt + 1;

    try {
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }
}

// ---------------------------------------------------------------------------
// Singleton Dio HTTP client with JWT interceptor + auto retry
// ---------------------------------------------------------------------------

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

    // Auto-retry interceptor — must be added AFTER the JWT interceptor
    // so retried requests also include the auth header
    dio.interceptors.add(_RetryInterceptor(dio));

    return dio;
  }
}

// ---------------------------------------------------------------------------
// Error helpers
// ---------------------------------------------------------------------------

/// Returns a structured [ApiError] with type and user-friendly message.
ApiError parseApiError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    final serverMessage = (data is Map && data.containsKey('error'))
        ? data['error'].toString()
        : null;

    if (error.type == DioExceptionType.connectionError) {
      return const ApiError(
        ApiErrorType.connection,
        'Tidak dapat terhubung ke server. Pastikan backend sudah berjalan.',
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiError(
        ApiErrorType.timeout,
        'Koneksi timeout. Coba lagi.',
      );
    }

    final statusCode = error.response?.statusCode ?? 0;
    if (statusCode >= 500) {
      return ApiError(
        ApiErrorType.serverError,
        serverMessage ?? 'Server error. Coba lagi nanti.',
      );
    }
    if (statusCode >= 400) {
      return ApiError(
        ApiErrorType.clientError,
        serverMessage ?? 'Permintaan tidak valid.',
      );
    }
  }

  return const ApiError(ApiErrorType.unknown, 'Terjadi kesalahan. Coba lagi.');
}

/// Backwards-compatible string extractor for existing call sites.
String extractApiError(Object error) => parseApiError(error).message;
