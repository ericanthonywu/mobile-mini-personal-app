import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:workmanager/workmanager.dart';
import 'package:expense_tracker/core/router/app_router.dart';
import 'package:expense_tracker/core/utils/widget_service.dart';
import 'package:expense_tracker/core/utils/notification_service.dart';
import 'package:expense_tracker/core/utils/background_task.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await WidgetService.init();

  // Initialize the notification plugin and request iOS permission.
  // This is fast (no network), so it's safe to await before runApp().
  await NotificationService.init();

  // Initialize workmanager callback registry (also fast, no network).
  await Workmanager().initialize(
    backgroundTaskCallback,
    isInDebugMode: false, // set to true to debug background task firing
  );

  runApp(
    // Riverpod provider scope — wraps the entire app
    const ProviderScope(
      child: ExpenseTrackerApp(),
    ),
  );

  // Schedule the notification AFTER the app is running — this makes an API
  // call and must not block runApp(). Running it post-frame ensures the app
  // is fully rendered before we hit the network.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Fetch latest budget data and schedule/refresh the 22:00 WIB notification
    await NotificationService.scheduleDailyReminder();

    // Register periodic background refresh (every hour when network is up)
    await Workmanager().registerPeriodicTask(
      'budget-notification-refresh',
      kBudgetRefreshTask,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  });
}



class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return Container(
      // Dark background behind everything — prevents white flash
      // during iOS overscroll bounce at the native layer.
      color: const Color(0xFF0D0D0D),
      child: MaterialApp.router(
        title: "Eric's Expense Tracker",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: router,
      ),
    );
  }
}
