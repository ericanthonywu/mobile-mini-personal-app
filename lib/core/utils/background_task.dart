import 'package:workmanager/workmanager.dart';
import 'package:expense_tracker/core/utils/notification_service.dart';

/// Unique task name registered with [Workmanager].
const String kBudgetRefreshTask = 'refreshBudgetNotification';

/// Top-level background task callback — must be a top-level function (not a
/// method) so it can be invoked in a separate Dart isolate.
///
/// iOS Background App Refresh will call this periodically (frequency managed
/// by iOS based on app usage patterns, typically every 15–60 minutes).
/// Android will call this at the requested [Duration] when the device is idle.
@pragma('vm:entry-point')
void backgroundTaskCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kBudgetRefreshTask) {
      // Re-initialize notification service in this fresh isolate — it has its
      // own memory space and must set up dependencies from scratch.
      await NotificationService.init();
      await NotificationService.scheduleDailyReminder();
    }
    return Future.value(true);
  });
}
