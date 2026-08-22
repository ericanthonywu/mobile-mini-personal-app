import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  String? storedToken;

  setUp(() {
    storedToken = 'valid_test_token';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        return storedToken;
      }
      if (methodCall.method == 'write') {
        storedToken = methodCall.arguments['value'] as String?;
        return null;
      }
      if (methodCall.method == 'delete') {
        storedToken = null;
        return null;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    ApiClient.onUnauthorized = null;
  });

  group('parseApiError', () {
    test('maps 401 status to ApiErrorType.unauthorized', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'error': 'Invalid or expired token'},
        ),
      );

      final apiError = parseApiError(dioException);
      expect(apiError.type, ApiErrorType.unauthorized);
      expect(apiError.message, 'Invalid or expired token');
    });

    test('falls back to default session expired message if no server message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
      );

      final apiError = parseApiError(dioException);
      expect(apiError.type, ApiErrorType.unauthorized);
      expect(apiError.message, 'Session expired. Please enter PIN again.');
    });
  });

  group('AuthNotifier Session Expiry', () {
    test('handleSessionExpired clears token and updates state to unauthenticated with message', () async {
      final notifier = AuthNotifier();

      // Simulate session expiry
      notifier.handleSessionExpired('Session expired. Please enter PIN again.');

      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.error, 'Session expired. Please enter PIN again.');
      expect(storedToken, isNull);

      notifier.dispose();
    });

    test('AuthNotifier registers itself as ApiClient.onUnauthorized', () {
      final notifier = AuthNotifier();
      expect(ApiClient.onUnauthorized, isNotNull);

      notifier.dispose();
      expect(ApiClient.onUnauthorized, isNull);
    });

    test('re-authenticating triggers provider invalidation', () async {
      int fetchCount = 0;
      final dummyDataProvider = FutureProvider<String>((ref) async {
        fetchCount++;
        return 'data_$fetchCount';
      });

      final container = ProviderContainer();

      // Keep an active listener on dummyDataProvider like a mounted screen does
      final sub = container.listen(dummyDataProvider, (_, __) {});

      // Listen to authProvider changes to invalidate data providers (same logic as in ExpenseTrackerApp)
      container.listen<AuthState>(authProvider, (previous, next) {
        if (previous?.status != AuthStatus.authenticated &&
            next.status == AuthStatus.authenticated) {
          container.invalidate(dummyDataProvider);
        }
      });

      // Initial read
      expect(await container.read(dummyDataProvider.future), 'data_1');
      expect(fetchCount, 1);

      // Transition to unauthenticated (session expired)
      container.read(authProvider.notifier).handleSessionExpired();
      expect(container.read(authProvider).status, AuthStatus.unauthenticated);

      // Re-authenticate (simulate successful login)
      container.read(authProvider.notifier).state = const AuthState(
        status: AuthStatus.authenticated,
      );

      // Wait a microtask for listener to fire
      await Future<void>.delayed(Duration.zero);

      // Provider was invalidated and refetched
      expect(await container.read(dummyDataProvider.future), 'data_2');
      expect(fetchCount, 2);

      sub.close();
      container.dispose();
    });
  });

  group('ApiClient 401 Interceptor', () {
    test('triggers onUnauthorized and clears token on 401 from protected endpoint', () async {
      bool unauthorizedTriggered = false;
      ApiClient.onUnauthorized = () {
        unauthorizedTriggered = true;
      };

      // Create a dio instance mimicking ApiClient interceptor logic
      final testDio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            options.headers['Authorization'] = 'Bearer $storedToken';
            handler.next(options);
          },
          onError: (error, handler) async {
            if (error.response?.statusCode == 401) {
              final path = error.requestOptions.path;
              final isLoginEndpoint =
                  path.endsWith(ApiEndpoints.login) || path == ApiEndpoints.login;
              if (!isLoginEndpoint) {
                await ApiClient.handleUnauthorized();
              }
            }
            handler.next(error);
          },
        ),
      );

      // Add custom adapter to return 401 for /budget
      testDio.httpClientAdapter = _MockAdapter(
        (options) => ResponseBody.fromString(
          '{"error": "Invalid or expired token"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      try {
        await testDio.get('/budget');
      } catch (_) {}

      expect(unauthorizedTriggered, isTrue);
      expect(storedToken, isNull);
    });

    test('does NOT trigger onUnauthorized on 401 from /auth/login', () async {
      bool unauthorizedTriggered = false;
      ApiClient.onUnauthorized = () {
        unauthorizedTriggered = true;
      };

      final testDio = Dio(BaseOptions(baseUrl: 'https://example.com'));
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            handler.next(options);
          },
          onError: (error, handler) async {
            if (error.response?.statusCode == 401) {
              final path = error.requestOptions.path;
              final isLoginEndpoint =
                  path.endsWith(ApiEndpoints.login) || path == ApiEndpoints.login;
              if (!isLoginEndpoint) {
                await ApiClient.handleUnauthorized();
              }
            }
            handler.next(error);
          },
        ),
      );

      // Add custom adapter to return 401 for /auth/login
      testDio.httpClientAdapter = _MockAdapter(
        (options) => ResponseBody.fromString(
          '{"error": "Invalid PIN"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );

      try {
        await testDio.post(ApiEndpoints.login, data: {'pin': '123456'});
      } catch (_) {}

      expect(unauthorizedTriggered, isFalse);
      expect(storedToken, equals('valid_test_token'));
    });
  });
}

class _MockAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions) handler;
  _MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
