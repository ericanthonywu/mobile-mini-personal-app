import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_tracker/core/utils/notification_service.dart';

/// Unique task name registered with [Workmanager].
const String kBudgetRefreshTask = 'refreshBudgetNotification';

/// Top-level background task callback — must be a top-level function (not a
/// method) so it can be invoked in a separate Dart isolate.
@pragma('vm:entry-point')
void backgroundTaskCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kBudgetRefreshTask) {
      // Re-initialize notification service in this fresh isolate — it has its
      // own memory space and must set up dependencies from scratch.
      await NotificationService.init();
      await NotificationService.scheduleDailyReminder();

      // Reschedule the next check for 21:00 WIB tomorrow
      await scheduleNextOneOffBudgetRefresh();
    }
    return Future.value(true);
  });
}

/// Calculates the delay until the next 21:00 WIB (Asia/Jakarta) and registers
/// a one-off background task with Workmanager.
Future<void> scheduleNextOneOffBudgetRefresh() async {
  final now = tz.TZDateTime.now(tz.local);
  var target = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21);

  // If it's already past 21:00 today, schedule for tomorrow 21:00
  if (target.isBefore(now)) {
    target = target.add(const Duration(days: 1));
  }

  final delay = target.difference(now);

  await Workmanager().registerOneOffTask(
    'budget-notification-refresh', // Keep unique name to replace old task configurations
    kBudgetRefreshTask,
    initialDelay: delay,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}
