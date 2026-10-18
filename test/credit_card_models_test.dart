import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budget/models/budget_model.dart';

void main() {
  group('Credit Card Billing Model Tests', () {
    test('BudgetSummaryModel parses creditCard correctly from JSON', () {
      final json = {
        'week': {
          'start': '2026-10-05T00:00:00.000Z',
          'end': '2026-10-11T23:59:59.000Z',
          'budget': 1000000,
          'realSpent': 350000,
          'totalSpent': 350000,
          'remaining': 650000,
          'percentUsed': 35,
          'isOverBudget': false,
        },
        'month': {
          'start': '2026-10-01T00:00:00.000Z',
          'end': '2026-10-31T23:59:59.000Z',
          'budget': 5000000,
          'realSpent': 4396462,
          'totalSpent': 4396462,
          'remaining': 603538,
          'percentUsed': 88,
          'isOverBudget': false,
        },
        'creditCard': {
          'start': '2026-10-04T00:00:00.000Z',
          'end': '2026-11-03T23:59:59.000Z',
          'budget': 5000000,
          'realSpent': 2541754,
          'totalSpent': 2541754,
          'remaining': 2458246,
          'percentUsed': 51,
          'isOverBudget': false,
          'cycleLabel': '4 Oct – 3 Nov 2026',
        },
      };

      final model = BudgetSummaryModel.fromJson(json);

      expect(model.creditCard, isNotNull);
      expect(model.creditCard!.budget, equals(5000000));
      expect(model.creditCard!.realSpent, equals(2541754));
      expect(model.creditCard!.totalSpent, equals(2541754));
      expect(model.creditCard!.remaining, equals(2458246));
      expect(model.creditCard!.percentUsed, equals(51));
      expect(model.creditCard!.isOverBudget, isFalse);
      expect(model.creditCard!.cycleLabel, equals('4 Oct – 3 Nov 2026'));
      expect(model.creditCard!.start.day, equals(4));
      expect(model.creditCard!.end.day, equals(3));
    });

    test('BudgetChartModel parses creditCard chart data correctly', () {
      final json = {
        'weekly': {
          'budget': 1000000,
          'days': [
            {'date': '2026-10-05', 'realSpent': 50000, 'totalSpent': 50000},
          ],
        },
        'monthly': {
          'budget': 5000000,
          'days': [
            {'date': '2026-10-01', 'realSpent': 100000, 'totalSpent': 100000},
          ],
        },
        'creditCard': {
          'budget': 5000000,
          'cycleLabel': '4 Oct – 3 Nov 2026',
          'days': [
            {'date': '2026-10-04', 'realSpent': 391400, 'totalSpent': 391400},
            {'date': '2026-10-05', 'realSpent': 335500, 'totalSpent': 335500},
          ],
        },
      };

      final chart = BudgetChartModel.fromJson(json);

      expect(chart.creditCard, isNotNull);
      expect(chart.creditCard!.budget, equals(5000000));
      expect(chart.creditCard!.cycleLabel, equals('4 Oct – 3 Nov 2026'));
      expect(chart.creditCard!.days.length, equals(2));
      expect(chart.creditCard!.days[0].date, equals('2026-10-04'));
      expect(chart.creditCard!.days[0].realSpent, equals(391400));
    });
  });
}
