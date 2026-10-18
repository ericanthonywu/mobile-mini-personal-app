import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/calendar/models/calendar_model.dart';

void main() {
  group('Calendar Models Tests', () {
    test('CalendarDailyModel parses correctly from JSON ("daily see daily")', () {
      final json = {
        'mode': 'daily',
        'date': '2026-10-18',
        'dayOfWeek': 7,
        'dayName': 'Sunday',
        'formattedDate': '18 Oktober 2026',
        'totalSpent': 250000,
        'realSpent': 250000,
        'transactionCount': 3,
        'monthDailyAverage': 180000,
        'monthTotal': 3240000,
        'transactions': [
          {
            'id': 'tx-1',
            'amount': 50000,
            'transaction_date': '2026-10-18T10:00:00.000Z',
            'merchant': 'STARBUCKS',
            'transaction_type': 'BCA CC',
            'notes': '',
            'category_id': 'c-1',
            'category_name': 'Food',
            'category_color': '#FF6B6B',
            'is_ignored': false,
            'email_message_id': 'm-1',
            'created_at': '2026-10-18T10:05:00.000Z',
            'updated_at': '2026-10-18T10:05:00.000Z',
            'total_split_amount': 0,
            'net_amount': 50000,
            'splits': [],
          },
          {
            'id': 'tx-2',
            'amount': 200000,
            'transaction_date': '2026-10-18T15:00:00.000Z',
            'merchant': 'UNIQLO',
            'transaction_type': 'BCA CC',
            'notes': '',
            'category_id': 'c-2',
            'category_name': 'Shopping',
            'category_color': '#4ECDC4',
            'is_ignored': false,
            'email_message_id': 'm-2',
            'created_at': '2026-10-18T15:05:00.000Z',
            'updated_at': '2026-10-18T15:05:00.000Z',
            'total_split_amount': 0,
            'net_amount': 200000,
            'splits': [],
          },
        ],
      };

      final daily = CalendarDailyModel.fromJson(json);

      expect(daily.mode, 'daily');
      expect(daily.date, '2026-10-18');
      expect(daily.totalSpent, 250000);
      expect(daily.transactionCount, 3);
      expect(daily.monthDailyAverage, 180000);
      expect(daily.transactions.length, 2);
      expect(daily.transactions.first.merchant, 'STARBUCKS');
      expect(daily.transactions.last.merchant, 'UNIQLO');
    });

    test('CalendarMonthlyModel parses correctly from JSON ("monthly see monthly")', () {
      final json = {
        'mode': 'monthly',
        'year': 2026,
        'month': 10,
        'monthName': 'Oktober',
        'formattedMonthYear': 'Oktober 2026',
        'totalSpent': 4500000,
        'transactionCount': 28,
        'activeDays': 15,
        'elapsedDays': 18,
        'averageDailySpent': 250000,
        'highestDay': {
          'date': '2026-10-05',
          'day': 5,
          'amount': 950000,
        },
        'days': [
          {
            'date': '2026-10-01',
            'day': 1,
            'dayOfWeek': 4,
            'totalSpent': 150000,
            'transactionCount': 2,
          },
          {
            'date': '2026-10-02',
            'day': 2,
            'dayOfWeek': 5,
            'totalSpent': 0,
            'transactionCount': 0,
          },
        ],
        'transactions': [],
      };

      final monthly = CalendarMonthlyModel.fromJson(json);

      expect(monthly.mode, 'monthly');
      expect(monthly.year, 2026);
      expect(monthly.month, 10);
      expect(monthly.monthName, 'Oktober');
      expect(monthly.totalSpent, 4500000);
      expect(monthly.transactionCount, 28);
      expect(monthly.activeDays, 15);
      expect(monthly.highestDay?.day, 5);
      expect(monthly.highestDay?.amount, 950000);
      expect(monthly.days.length, 2);
      expect(monthly.days.first.day, 1);
      expect(monthly.days.first.totalSpent, 150000);
    });

    test('CalendarYearlyModel parses correctly with average monthly expense ("yearly see avg monthly")', () {
      final json = {
        'mode': 'yearly',
        'year': 2026,
        'totalSpent': 36000000,
        'transactionCount': 180,
        'elapsedMonths': 10,
        'averageMonthlySpent': 3600000,
        'highestMonth': {
          'month': 7,
          'monthName': 'Juli',
          'amount': 5200000,
        },
        'lowestMonth': {
          'month': 2,
          'monthName': 'Februari',
          'amount': 2100000,
        },
        'months': [
          {
            'month': 1,
            'monthName': 'Januari',
            'shortName': 'Jan',
            'totalSpent': 3500000,
            'transactionCount': 15,
            'diffFromAvg': -100000,
            'ratioToAvg': 0.97,
          },
          {
            'month': 7,
            'monthName': 'Juli',
            'shortName': 'Jul',
            'totalSpent': 5200000,
            'transactionCount': 22,
            'diffFromAvg': 1600000,
            'ratioToAvg': 1.44,
          },
        ],
      };

      final yearly = CalendarYearlyModel.fromJson(json);

      expect(yearly.mode, 'yearly');
      expect(yearly.year, 2026);
      expect(yearly.totalSpent, 36000000);
      expect(yearly.elapsedMonths, 10);
      expect(yearly.averageMonthlySpent, 3600000); // Prominent average monthly requirement
      expect(yearly.highestMonth?.monthName, 'Juli');
      expect(yearly.highestMonth?.amount, 5200000);
      expect(yearly.lowestMonth?.monthName, 'Februari');
      expect(yearly.lowestMonth?.amount, 2100000);
      expect(yearly.months.length, 2);
      expect(yearly.months.first.diffFromAvg, -100000);
      expect(yearly.months.last.diffFromAvg, 1600000);
    });

    test('CalendarViewMode labels are mapped appropriately', () {
      expect(CalendarViewMode.daily.label, 'Harian');
      expect(CalendarViewMode.monthly.label, 'Bulanan');
      expect(CalendarViewMode.yearly.label, 'Tahunan');
    });
  });
}
