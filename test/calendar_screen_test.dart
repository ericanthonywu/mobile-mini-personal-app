import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/calendar/models/calendar_model.dart';
import 'package:expense_tracker/features/calendar/providers/calendar_provider.dart';
import 'package:expense_tracker/features/calendar/screens/calendar_screen.dart';

void main() {
  testWidgets('CalendarScreen displays mode switchers and renders Monthly, Yearly, and Daily views',
      (WidgetTester tester) async {
    final now = DateTime.now();

    final mockMonthly = CalendarMonthlyModel(
      mode: 'monthly',
      year: now.year,
      month: now.month,
      monthName: 'Oktober',
      formattedMonthYear: 'Oktober ${now.year}',
      totalSpent: 4250000,
      transactionCount: 24,
      activeDays: 14,
      elapsedDays: 18,
      averageDailySpent: 236111,
      highestDay: const CalendarHighestDay(date: '2026-10-05', day: 5, amount: 850000),
      days: [
        CalendarMonthDay(
          date: '${now.year}-10-01',
          day: 1,
          dayOfWeek: 4,
          totalSpent: 120000,
          transactionCount: 1,
        ),
      ],
      transactions: const [],
    );

    final mockYearly = CalendarYearlyModel(
      mode: 'yearly',
      year: now.year,
      totalSpent: 42500000,
      transactionCount: 220,
      elapsedMonths: 10,
      averageMonthlySpent: 4250000, // avg monthly
      highestMonth: const CalendarMonthExtreme(month: 7, monthName: 'Juli', amount: 5500000),
      lowestMonth: const CalendarMonthExtreme(month: 2, monthName: 'Februari', amount: 2000000),
      months: [
        const CalendarYearMonth(
          month: 1,
          monthName: 'Januari',
          shortName: 'Jan',
          totalSpent: 3800000,
          transactionCount: 20,
          diffFromAvg: -450000,
          ratioToAvg: 0.89,
        ),
      ],
    );

    final mockDaily = CalendarDailyModel(
      mode: 'daily',
      date: '${now.year}-10-18',
      dayOfWeek: 7,
      dayName: 'Sunday',
      formattedDate: '18 Oktober ${now.year}',
      totalSpent: 320000,
      realSpent: 320000,
      transactionCount: 3,
      monthDailyAverage: 150000,
      monthTotal: 4250000,
      transactions: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarMonthlyProvider((year: now.year, month: now.month))
              .overrideWith((ref) async => mockMonthly),
          calendarYearlyProvider(now.year)
              .overrideWith((ref) async => mockYearly),
          calendarDailyProvider('${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}')
              .overrideWith((ref) async => mockDaily),
        ],
        child: const MaterialApp(
          home: CalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('Kalender Pengeluaran'), findsOneWidget);

    // Verify all 3 mode switches exist
    expect(find.text('Harian'), findsOneWidget);
    expect(find.text('Bulanan'), findsOneWidget);
    expect(find.text('Tahunan'), findsOneWidget);

    // Default is Bulanan (Monthly see monthly)
    expect(find.textContaining('Total Bulan'), findsOneWidget);
    expect(find.textContaining('Rata-rata / Hari'), findsOneWidget);

    // Tap 'Tahunan' mode ("yearly see avg monthly")
    await tester.tap(find.text('Tahunan'));
    await tester.pumpAndSettle();

    expect(find.text('Rata-rata Pengeluaran Bulanan'), findsOneWidget);
    expect(find.text('AVG MONTHLY'), findsOneWidget);
    expect(find.text('/ bulan'), findsOneWidget);

    // Tap 'Harian' mode ("daily see daily")
    await tester.tap(find.text('Harian'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pengeluaran Hari'), findsOneWidget);
  });
}
