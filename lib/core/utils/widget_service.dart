import 'package:home_widget/home_widget.dart';
import 'package:expense_tracker/core/config/app_config.dart';

/// Utility class to trigger a WidgetKit timeline reload from Flutter.
///
/// Call [refreshWidget] after any data change (sync, manual refresh) so
/// the home screen widget fetches fresh budget data from the API immediately,
/// rather than waiting for its next scheduled 30-minute update.
class WidgetService {
  WidgetService._();

  /// The iOS app group identifier — must match the entitlements on both the
  /// Runner target and the ExpenseWidget extension target.
  static const _appGroupId = 'group.com.ericanthonywu.expenseTracker';

  /// The widget kind string — must match `ExpenseWidget.kind` in Swift.
  static const _widgetKind = 'ExpenseWidget';

  /// Initialize home_widget and save current environment BASE_URL to App Group.
  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
    await HomeWidget.saveWidgetData<String>('base_url', AppConfig.baseUrl);
  }

  /// Ask WidgetKit to reload the timeline for all ExpenseWidget instances.
  ///
  /// iOS will call `getTimeline()` on the Swift side shortly after, which
  /// makes a fresh API call and re-renders the widget. This is battery-safe
  /// because it only runs when the user is already actively using the app.
  static Future<void> refreshWidget() async {
    try {
      await HomeWidget.updateWidget(
        iOSName: _widgetKind,
        qualifiedAndroidName: '', // Android not needed
      );
    } catch (_) {
      // Widget refresh failing silently is acceptable — app functionality unaffected.
    }
  }
}
