import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/core/network/api_client.dart';
import 'package:expense_tracker/core/network/api_endpoints.dart';
import 'package:expense_tracker/features/calendar/models/calendar_model.dart';

/// Currently active calendar view mode (daily, monthly, yearly).
final selectedCalendarModeProvider =
    StateProvider<CalendarViewMode>((ref) => CalendarViewMode.monthly);

/// Selected date for daily mode.
final selectedCalendarDateProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

/// Selected year for monthly & yearly modes.
final selectedCalendarYearProvider =
    StateProvider<int>((ref) => DateTime.now().year);

/// Selected month (1..12) for monthly mode.
final selectedCalendarMonthProvider =
    StateProvider<int>((ref) => DateTime.now().month);

/// Selected date string (YYYY-MM-DD) inside monthly grid to inspect transactions.
final selectedCalendarGridDayProvider =
    StateProvider<String?>((ref) => null);

/// Fetches daily calendar expense data.
final calendarDailyProvider =
    FutureProvider.family<CalendarDailyModel, String>((ref, dateStr) async {
  final response = await ApiClient.instance.get(
    ApiEndpoints.budgetCalendar,
    queryParameters: {
      'mode': 'daily',
      'date': dateStr,
    },
  );
  return CalendarDailyModel.fromJson(response.data as Map<String, dynamic>);
});

/// Fetches monthly calendar expense data.
final calendarMonthlyProvider = FutureProvider.family<
    CalendarMonthlyModel, ({int year, int month})>((ref, args) async {
  final response = await ApiClient.instance.get(
    ApiEndpoints.budgetCalendar,
    queryParameters: {
      'mode': 'monthly',
      'year': args.year,
      'month': args.month,
    },
  );
  return CalendarMonthlyModel.fromJson(response.data as Map<String, dynamic>);
});

/// Fetches yearly calendar expense data with average monthly calculation.
final calendarYearlyProvider =
    FutureProvider.family<CalendarYearlyModel, int>((ref, year) async {
  final response = await ApiClient.instance.get(
    ApiEndpoints.budgetCalendar,
    queryParameters: {
      'mode': 'yearly',
      'year': year,
    },
  );
  return CalendarYearlyModel.fromJson(response.data as Map<String, dynamic>);
});
