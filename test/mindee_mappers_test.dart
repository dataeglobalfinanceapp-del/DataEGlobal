import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:savetep/features/auth/screens/scan_screen/deposit_screen/deposit_mindee_mapper.dart';
import 'package:savetep/features/auth/screens/scan_screen/expense_screen/expense_mindee_mapper.dart';
import 'package:savetep/features/auth/screens/scan_screen/expense_screen/mindee_expense_fields.dart';
import 'package:savetep/features/auth/screens/scan_screen/expense_screen/scan_expense_screen.dart';
import 'package:savetep/features/auth/screens/scan_screen/mindee/mindee_analysis_models.dart';
import 'package:savetep/features/auth/screens/scan_screen/mindee/mindee_mapping.dart';

void main() {
  final image = XFile.fromData(
    Uint8List.fromList(<int>[1]),
    name: 'scan.jpg',
    path: 'scan.jpg',
  );

  group('ExpenseMindeeMapper', () {
    const mapper = ExpenseMindeeMapper();

    test('category catalog matches the configured Mindee classifications', () {
      expect(
        ExpenseCategory.values
            .map((ExpenseCategory category) => category.label)
            .toList(growable: false),
        <String>[
          'Energy',
          'Loan Obligation',
          'Payroll',
          'Business licenses and permits',
          'Food Purchase',
          'Restaurant supplies',
          'Advertising and promotion',
          'software',
          'pest control',
          'Internet',
          'Maintenance',
          'Insurance',
          'Rent',
          'Office Supplies',
          'Meal, entertainment',
          'merchant accounting fees',
          'gas',
          'water',
          'electric',
          'donation',
          'professional fees',
        ],
      );
    });

    test('maps the supported expense fields', () {
      final mapped = mapper.map(
        result: _result(<String, Object?>{
          'supplier_name': 'City Gas',
          'date': '2026-08-06',
          'time': '14:35',
          'total_amount': 125.75,
          'tips_gratuity': 5.25,
          'purchase_category': 'gas',
          'card_last4': '7281',
        }),
        image: image,
        fallbackDate: DateTime(2026, 1, 1),
        currentCategory: ExpenseCategory.energy,
      );

      expect(mapped.totalAmount, 125.75);
      expect(mapped.tipsGratuity, 5.25);
      expect(mapped.transactionDate, DateTime(2026, 8, 6, 14, 35));
      expect(mapped.category, ExpenseCategory.gas);
      expect(mapped.payee, 'City Gas');
      expect(mapped.cardLast4, '7281');
      expect(mapped.receiptImage, same(image));
    });

    test('preserves current category when missing or unsupported', () {
      for (final value in <Object?>[null, 'Travel', 'Other', 'Shopping']) {
        final mapped = mapper.map(
          result: _result(<String, Object?>{'purchase_category': value}),
          image: image,
          fallbackDate: DateTime(2026, 8, 6),
          currentCategory: ExpenseCategory.rent,
        );
        expect(mapped.category, ExpenseCategory.rent);
      }
    });

    test('maps every configured purchase category', () {
      for (final category in ExpenseCategory.values) {
        final mapped = mapper.map(
          result: _result(<String, Object?>{
            'purchase_category': category.label,
          }),
          image: image,
          fallbackDate: DateTime(2026, 8, 6),
          currentCategory: ExpenseCategory.energy,
        );

        expect(mapped.category, category);
      }
    });

    test('missing optional values map to existing model defaults', () {
      final mapped = mapper.map(
        result: const MindeeAnalysisResult(
          fields: <String, MindeeFieldValue>{},
        ),
        image: image,
        fallbackDate: DateTime(2026, 8, 6),
        currentCategory: ExpenseCategory.payroll,
      );

      expect(mapped.totalAmount, 0);
      expect(mapped.tipsGratuity, 0);
      expect(mapped.payee, isEmpty);
      expect(mapped.cardLast4, isNull);
      expect(mapped.category, ExpenseCategory.payroll);
      expect(mapped.transactionDate, DateTime(2026, 8, 6));
    });

    test('malformed amount does not silently map to zero', () {
      expect(
        () => mapper.map(
          result: _result(<String, Object?>{'total_amount': '125.75'}),
          image: image,
          fallbackDate: DateTime(2026, 8, 6),
          currentCategory: ExpenseCategory.energy,
        ),
        throwsA(isA<MindeeFieldParseException>()),
      );
    });

    test('malformed tips do not silently map to zero', () {
      expect(
        () => mapper.map(
          result: _result(<String, Object?>{'tips_gratuity': '5.25'}),
          image: image,
          fallbackDate: DateTime(2026, 8, 6),
          currentCategory: ExpenseCategory.energy,
        ),
        throwsA(isA<MindeeFieldParseException>()),
      );
    });

    test('tips remain separate from the receipt total', () {
      final mapped = mapper.map(
        result: _result(<String, Object?>{
          'total_amount': 125.75,
          'tips_gratuity': 5.25,
        }),
        image: image,
        fallbackDate: DateTime(2026, 8, 6),
        currentCategory: ExpenseCategory.energy,
      );

      expect(mapped.totalAmount, 125.75);
      expect(mapped.tipsGratuity, 5.25);
    });

    test('ignores the superseded expense field keys', () {
      final fallback = DateTime(2026, 1, 2, 9, 15);
      final mapped = mapper.map(
        result: _result(<String, Object?>{
          'check_number': '4182',
          'transaction_date': '2026-08-06',
          'payee': 'Old Payee',
          'category': 'gas',
        }),
        image: image,
        fallbackDate: fallback,
        currentCategory: ExpenseCategory.rent,
      );

      expect(mapped.transactionDate, fallback);
      expect(mapped.payee, isEmpty);
      expect(mapped.category, ExpenseCategory.rent);
    });

    test('normalizes a full expense card number to its last four digits', () {
      final mapped = mapper.map(
        result: _result(<String, Object?>{'card_last4': '4111 1111 1111 7281'}),
        image: image,
        fallbackDate: DateTime(2026, 8, 6),
        currentCategory: ExpenseCategory.energy,
      );

      expect(mapped.cardLast4, '7281');
    });
  });

  group('Mindee expense date and time', () {
    test('parses supported 24-hour and 12-hour time formats', () {
      expect(
        parseMindeeExpenseDateTime(
          dateValue: '2026-08-06',
          timeValue: '14:35',
          fallback: DateTime(2026),
        ),
        DateTime(2026, 8, 6, 14, 35),
      );
      expect(
        parseMindeeExpenseDateTime(
          dateValue: '2026-08-06',
          timeValue: '14:35:42',
          fallback: DateTime(2026),
        ),
        DateTime(2026, 8, 6, 14, 35, 42),
      );
      expect(
        parseMindeeExpenseDateTime(
          dateValue: '2026-08-06',
          timeValue: '2:35 PM',
          fallback: DateTime(2026),
        ),
        DateTime(2026, 8, 6, 14, 35),
      );
      expect(
        parseMindeeExpenseDateTime(
          dateValue: '2026-08-06',
          timeValue: '02:35 am',
          fallback: DateTime(2026),
        ),
        DateTime(2026, 8, 6, 2, 35),
      );
    });

    test('uses midnight when time is missing or malformed', () {
      expect(
        parseMindeeExpenseDateTime(
          dateValue: '2026-08-06',
          timeValue: null,
          fallback: DateTime(2026),
        ),
        DateTime(2026, 8, 6),
      );
      expect(
        parseMindeeExpenseDateTime(
          dateValue: '2026-08-06',
          timeValue: '25:61',
          fallback: DateTime(2026),
        ),
        DateTime(2026, 8, 6),
      );
    });

    test('invalid dates still fail with a typed mapping error', () {
      expect(
        () => parseMindeeExpenseDateTime(
          dateValue: '08/06/2026',
          timeValue: '14:35',
          fallback: DateTime(2026),
        ),
        throwsA(isA<MindeeFieldParseException>()),
      );
    });

    test('replacing the date preserves the extracted time', () {
      expect(
        replaceDateOnly(DateTime(2026, 8, 6, 14, 35, 42), DateTime(2026, 9, 7)),
        DateTime(2026, 9, 7, 14, 35, 42),
      );
    });
  });

  group('DepositMindeeMapper', () {
    const mapper = DepositMindeeMapper();

    test('maps fields and preserves the automatic order number', () {
      final mapped = mapper.map(
        result: _result(<String, Object?>{
          'total_amount': 1072,
          'credit_debit_amount': 558,
          'card_last4': '1234',
          'cash_amount': 514,
          'gift_card_amount': 0,
          'other_amount': 0,
          'transaction_date': '2026-08-06',
        }),
        image: image,
        fallbackDate: DateTime(2026, 1, 1),
        currentAutomaticOrderNumber: 'AUTO-42',
      );

      expect(mapped.orderNumber, 'AUTO-42');
      expect(mapped.totalAmount, 1072);
      expect(mapped.creditDeposit, 558);
      expect(mapped.cardLastFour, '1234');
      expect(mapped.cash, 514);
      expect(mapped.giftCard, 0);
      expect(mapped.other, 0);
      expect(mapped.transactionDate, DateTime(2026, 8, 6));
      expect(mapped.receiptImage, same(image));
    });

    test('missing optional amounts map to zero', () {
      final mapped = mapper.map(
        result: const MindeeAnalysisResult(
          fields: <String, MindeeFieldValue>{},
        ),
        image: image,
        fallbackDate: DateTime(2026, 8, 6),
        currentAutomaticOrderNumber: 'AUTO-43',
      );

      expect(mapped.totalAmount, 0);
      expect(mapped.creditDeposit, 0);
      expect(mapped.cash, 0);
      expect(mapped.giftCard, 0);
      expect(mapped.other, 0);
    });
  });

  group('shared mapping rules', () {
    test('normalizes a full card number to only its final four digits', () {
      expect(normalizeOptionalCardLast4('4111 1111 1111 7281'), '7281');
      expect(normalizeOptionalCardLast4(''), isNull);
    });

    test('rejects an unreliable card suffix and malformed date', () {
      expect(
        () => normalizeOptionalCardLast4('123'),
        throwsA(isA<MindeeFieldParseException>()),
      );
      expect(
        () => parseMindeeDate('08/06/2026', fallback: DateTime(2026, 1, 1)),
        throwsA(isA<MindeeFieldParseException>()),
      );
    });

    test('compares deposit totals in integer cents', () {
      expect(
        depositPaymentBreakdownMatches(
          totalAmount: 0.3,
          creditDeposit: 0.1,
          cash: 0.2,
          giftCard: 0,
          other: 0,
        ),
        isTrue,
      );
      expect(
        depositPaymentBreakdownMatches(
          totalAmount: 10,
          creditDeposit: 9.99,
          cash: 0,
          giftCard: 0,
          other: 0,
        ),
        isFalse,
      );
    });
  });
}

MindeeAnalysisResult _result(Map<String, Object?> values) {
  return MindeeAnalysisResult(
    fields: <String, MindeeFieldValue>{
      for (final entry in values.entries)
        entry.key: MindeeFieldValue(value: entry.value),
    },
  );
}
