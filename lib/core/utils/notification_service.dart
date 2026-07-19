import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_tracker/core/config/app_config.dart';
import 'package:expense_tracker/core/storage/secure_storage.dart';

/// Handles scheduling the daily 22:00 WIB budget reminder notification.
///
/// The notification is registered with the OS scheduler, so it fires even when
/// the app is completely killed. Call [scheduleDailyReminder] on startup and
/// from the background task to keep the content fresh.
class NotificationService {
  NotificationService._();

  static const int _notificationId = 42; // fixed ID — we replace it each time
  static const String _channelId = 'budget_reminder';
  static const String _channelName = 'Pengingat Anggaran';
  static const String _channelDesc = 'Notifikasi harian pengeluaran vs anggaran pada pukul 22.00 WIB';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  /// Initialize the notification plugin and request iOS permission.
  /// Must be called once from [main] before any scheduling.
  static Future<void> init() async {
    // Initialize timezone database
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Request notification permission on iOS 16+
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ---------------------------------------------------------------------------
  // Schedule
  // ---------------------------------------------------------------------------

  /// Fetch latest budget data, then cancel the old notification and schedule
  /// a new daily reminder at 22:00 WIB (Asia/Jakarta).
  ///
  /// Safe to call from main isolate and from background isolate.
  static Future<void> scheduleDailyReminder() async {
    try {
      final data = await _fetchBudgetData();
      if (data == null) return;

      final title = _buildTitle(data);
      final body = _buildBody(data);

      // Cancel previous schedule before re-registering
      await _plugin.cancel(_notificationId);

      final now = tz.TZDateTime.now(tz.local);
      // Next 22:00 WIB — if it's already past 22:00 today, schedule for tomorrow
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 22);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _notificationId,
        title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
        // Repeat daily at the same time — OS handles the repeat even when killed
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('[NotificationService] Scheduled daily reminder at $scheduled');
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule: $e');
    }
  }

  /// Cancel all pending notifications.
  static Future<void> cancelAll() => _plugin.cancelAll();

  // ---------------------------------------------------------------------------
  // Data fetching — uses plain Dio so it works in background isolates too
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> _fetchBudgetData() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return null; // not logged in

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

      final response = await dio.get('/budget');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[NotificationService] Budget fetch failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Message builders
  // ---------------------------------------------------------------------------

  static String _buildTitle(Map<String, dynamic> data) {
    final month = data['month'] as Map<String, dynamic>;
    final isOverWeek = (data['week']['isOverBudget'] as bool? ?? false);
    final isOverMonth = (month['isOverBudget'] as bool? ?? false);

    if (isOverWeek || isOverMonth) return '⚠️ Anggaran Terlampaui!';
    return '🔔 Ringkasan Pengeluaran Hari Ini';
  }

  static String _buildBody(Map<String, dynamic> data) {
    final week = data['week'] as Map<String, dynamic>;
    final month = data['month'] as Map<String, dynamic>;

    final weekSpent = (week['realSpent'] as num).toInt();
    final weekBudget = (week['budget'] as num).toInt();
    final weekPct = (week['percentUsed'] as num).toInt();

    final monthSpent = (month['realSpent'] as num).toInt();
    final monthBudget = (month['budget'] as num).toInt();
    final monthPct = (month['percentUsed'] as num).toInt();

    final weekOverIcon = weekPct > 100 ? '🔴' : weekPct >= 80 ? '🟡' : '🟢';
    final monthOverIcon = monthPct > 100 ? '🔴' : monthPct >= 80 ? '🟡' : '🟢';

    return '$weekOverIcon Minggu ini: ${_fmt(weekSpent)} / ${_fmt(weekBudget)} ($weekPct%)\n'
        '$monthOverIcon Bulan ini: ${_fmt(monthSpent)} / ${_fmt(monthBudget)} ($monthPct%)';
  }

  /// Compact Rupiah formatter: 1200000 → "Rp 1,2jt", 250000 → "Rp 250rb"
  static String _fmt(int amount) {
    const int oneMillion = 1000000;
    const int oneThousand = 1000;
    if (amount >= oneMillion) {
      final juta = amount / oneMillion;
      final display = juta == juta.truncateToDouble()
          ? juta.toInt().toString()
          : juta.toStringAsFixed(1).replaceAll('.', ',');
      return 'Rp ${display}jt';
    }
    if (amount >= oneThousand) {
      final ribu = amount / oneThousand;
      final display = ribu == ribu.truncateToDouble()
          ? ribu.toInt().toString()
          : ribu.toStringAsFixed(0);
      return 'Rp ${display}rb';
    }
    return 'Rp $amount';
  }
}
