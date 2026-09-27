import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/breakdown/models/breakdown_model.dart';
import 'package:expense_tracker/features/breakdown/models/ai_summary_model.dart';
import 'package:expense_tracker/core/utils/notification_service.dart';

void main() {
  group('Breakdown and AI Models', () {
    test('CategoryBreakdownResponse parses correctly from JSON', () {
      final json = {
        'period': 'month',
        'label': 'September 2026',
        'totalSpent': 2500000,
        'totalCount': 18,
        'uncategorizedCount': 2,
        'uncategorizedSpent': 150000,
        'categories': [
          {
            'categoryId': 'cat-1',
            'categoryName': 'Food',
            'categoryColor': '#FF6B6B',
            'transactionCount': 10,
            'totalAmount': 1500000,
            'averageAmount': 150000,
            'percentage': 60.0,
          },
          {
            'categoryId': null,
            'categoryName': 'Uncategorized',
            'categoryColor': null,
            'transactionCount': 2,
            'totalAmount': 150000,
            'averageAmount': 75000,
            'percentage': 6.0,
          }
        ],
        'topMerchants': [
          {
            'merchant': 'STARBUCKS',
            'totalSpent': 500000,
            'count': 5,
          }
        ],
      };

      final response = CategoryBreakdownResponse.fromJson(json);

      expect(response.period, 'month');
      expect(response.label, 'September 2026');
      expect(response.totalSpent, 2500000);
      expect(response.totalCount, 18);
      expect(response.uncategorizedCount, 2);
      expect(response.uncategorizedSpent, 150000);
      expect(response.categories.length, 2);
      expect(response.categories[0].categoryName, 'Food');
      expect(response.categories[0].percentage, 60.0);
      expect(response.categories[1].categoryId, isNull);
      expect(response.topMerchants.length, 1);
      expect(response.topMerchants[0].merchant, 'STARBUCKS');
    });

    test('AiExpenseSummaryResponse parses correctly from JSON', () {
      final json = {
        'period': 'month',
        'label': 'September 2026',
        'totalSpent': 2500000,
        'totalCount': 18,
        'ai': {
          'healthScore': 'healthy',
          'summary': 'Pengeluaran terkendali dengan baik bulan ini.',
          'keyInsights': [
            'Pengeluaran Food mendominasi 60% anggaran.',
            'Tidak ada pengeluaran impulsif berlebihan.',
          ],
          'recommendations': [
            'Pertahankan alokasi belanja saat ini.',
          ],
          'generatedAt': '2026-09-27T16:30:00.000Z',
        }
      };

      final response = AiExpenseSummaryResponse.fromJson(json);

      expect(response.period, 'month');
      expect(response.ai.healthScore, 'healthy');
      expect(response.ai.summary, contains('terkendali'));
      expect(response.ai.keyInsights.length, 2);
      expect(response.ai.recommendations.length, 1);
    });

    test('NotificationService has valid ntfy configuration', () {
      expect(NotificationService.ntfyTopic, isNotEmpty);
      expect(NotificationService.ntfyServer, contains('ntfy.sh'));
    });
  });
}
