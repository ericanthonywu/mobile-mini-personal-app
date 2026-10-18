import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/transactions/models/transaction_model.dart';

void main() {
  group('Split Payment Model Tests', () {
    test('SplitPaymentModel serializes and parses correctly from JSON', () {
      final json = {
        'id': 'split-1',
        'transaction_id': 'tx-100',
        'amount': 50000,
        'paid_by': 'Budi',
        'notes': 'Patungan sushi',
        'created_at': '2026-10-12T12:00:00.000',
        'updated_at': '2026-10-12T12:00:00.000',
      };

      final split = SplitPaymentModel.fromJson(json);

      expect(split.id, 'split-1');
      expect(split.transactionId, 'tx-100');
      expect(split.amount, 50000);
      expect(split.paidBy, 'Budi');
      expect(split.notes, 'Patungan sushi');
      expect(split.createdAt, DateTime.parse('2026-10-12T12:00:00.000'));
      expect(split.toJson()['amount'], 50000);
      expect(split.toJson()['paid_by'], 'Budi');
    });

    test('TransactionModel calculates netAmount and totalSplitAmount correctly without splits', () {
      final json = {
        'id': 'tx-1',
        'amount': 150000,
        'transaction_date': '2026-10-12T10:00:00.000',
        'merchant': 'Starbucks',
        'transaction_type': 'CC',
        'notes': '',
        'category_id': null,
        'category_name': null,
        'category_color': null,
        'is_ignored': false,
        'email_message_id': 'msg-1',
        'created_at': '2026-10-12T10:00:00.000',
        'updated_at': '2026-10-12T10:00:00.000',
        'splits': [],
      };

      final tx = TransactionModel.fromJson(json);

      expect(tx.amount, 150000);
      expect(tx.originalAmount, 150000);
      expect(tx.totalSplitAmount, 0);
      expect(tx.netAmount, 150000);
      expect(tx.hasSplits, false);
      expect(tx.splits, isEmpty);
    });

    test('TransactionModel calculates netAmount and totalSplitAmount correctly with multiple splits', () {
      final json = {
        'id': 'tx-2',
        'amount': 300000,
        'transaction_date': '2026-10-12T12:30:00.000',
        'merchant': 'Sushi Tei',
        'transaction_type': 'CC',
        'notes': 'Lunch tim',
        'category_id': null,
        'category_name': null,
        'category_color': null,
        'is_ignored': false,
        'email_message_id': 'msg-2',
        'created_at': '2026-10-12T12:30:00.000',
        'updated_at': '2026-10-12T12:30:00.000',
        'splits': [
          {
            'id': 'sp-1',
            'transaction_id': 'tx-2',
            'amount': 100000,
            'paid_by': 'Budi',
            'notes': 'Transfer BCA',
            'created_at': '2026-10-12T13:00:00.000',
            'updated_at': '2026-10-12T13:00:00.000',
          },
          {
            'id': 'sp-2',
            'transaction_id': 'tx-2',
            'amount': 100000,
            'paid_by': 'Citra',
            'notes': 'QRIS',
            'created_at': '2026-10-12T13:05:00.000',
            'updated_at': '2026-10-12T13:05:00.000',
          },
        ],
        'total_split_amount': 200000,
        'net_amount': 100000,
      };

      final tx = TransactionModel.fromJson(json);

      expect(tx.amount, 300000); // BCA original price preserved for recon!
      expect(tx.originalAmount, 300000);
      expect(tx.totalSplitAmount, 200000);
      expect(tx.netAmount, 100000); // Remaining out-of-pocket expense
      expect(tx.hasSplits, true);
      expect(tx.splits.length, 2);
      expect(tx.splits[0].paidBy, 'Budi');
      expect(tx.splits[1].paidBy, 'Citra');
    });

    test('TransactionModel handles 100% split where net amount becomes 0', () {
      final json = {
        'id': 'tx-3',
        'amount': 250000,
        'transaction_date': '2026-10-12T14:00:00.000',
        'merchant': 'Tokopedia',
        'transaction_type': 'CC',
        'notes': 'Titipan teman',
        'category_id': null,
        'category_name': null,
        'category_color': null,
        'is_ignored': false,
        'email_message_id': 'msg-3',
        'created_at': '2026-10-12T14:00:00.000',
        'updated_at': '2026-10-12T14:00:00.000',
        'splits': [
          {
            'id': 'sp-3',
            'transaction_id': 'tx-3',
            'amount': 250000,
            'paid_by': 'Andi',
            'notes': 'Titip beli headset',
            'created_at': '2026-10-12T14:10:00.000',
            'updated_at': '2026-10-12T14:10:00.000',
          },
        ],
      };

      final tx = TransactionModel.fromJson(json);

      expect(tx.originalAmount, 250000);
      expect(tx.totalSplitAmount, 250000);
      expect(tx.netAmount, 0); // Completely reimbursed
      expect(tx.hasSplits, true);
    });
  });
}
