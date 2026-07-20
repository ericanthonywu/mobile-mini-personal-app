import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/auth/providers/auth_provider.dart';
import 'package:expense_tracker/features/auth/screens/login_screen.dart';
import 'package:expense_tracker/features/auth/screens/splash_screen.dart';
import 'package:expense_tracker/features/dashboard/screens/dashboard_screen.dart';
import 'package:expense_tracker/features/transactions/screens/transactions_screen.dart';
import 'package:expense_tracker/features/categories/screens/categories_screen.dart';
import 'package:expense_tracker/features/budget/screens/budget_screen.dart';
import 'package:expense_tracker/shared/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final status = authState.status;
      final isUnknown = status == AuthStatus.unknown;
      final isAuthenticated = status == AuthStatus.authenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isLoginRoute = state.matchedLocation == '/login';

      // Still resolving token — show splash
      if (isUnknown) return isSplash ? null : '/splash';

      // Auth resolved — leave splash
      if (isSplash) {
        return isAuthenticated ? '/' : '/login';
      }

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (_, __) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                builder: (_, __) => const CategoriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/budget',
                builder: (_, __) => const BudgetScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
