import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/core/storage/secure_storage.dart';

/// Auth state
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({AuthStatus? status, String? error, bool? isLoading}) {
    return AuthState(
      status: status ?? this.status,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    ApiClient.onUnauthorized = handleSessionExpired;
    _checkExistingToken();
  }

  @override
  void dispose() {
    if (ApiClient.onUnauthorized == handleSessionExpired) {
      ApiClient.onUnauthorized = null;
    }
    super.dispose();
  }

  Future<void> _checkExistingToken() async {
    final hasToken = await SecureStorage.hasToken();
    if (!mounted) return;
    state = state.copyWith(
      status: hasToken ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  /// Handles 401 Unauthorized / expired JWT session
  void handleSessionExpired([String? message]) {
    SecureStorage.clearToken();
    if (!mounted) return;
    if (state.status != AuthStatus.unauthenticated || state.error == null) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: message ?? 'Session expired. Please enter PIN again.',
      );
    }
  }

  Future<void> login(String pin) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.post(
        ApiEndpoints.login,
        data: {'pin': pin},
      );
      final token = response.data['token'] as String;
      await SecureStorage.setToken(token);
      if (!mounted) return;
      state = state.copyWith(status: AuthStatus.authenticated, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: extractApiError(e),
        status: AuthStatus.unauthenticated,
      );
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearToken();
    if (!mounted) return;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
