import 'package:savetep/services/card_last_four.dart';

import 'mindee_analysis_models.dart';

DateTime parseMindeeDate(String? value, {required DateTime fallback}) {
  if (value == null || value.trim().isEmpty) return fallback;

  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) {
    throw const MindeeFieldParseException(
      fieldName: 'transaction_date',
      expectedType: 'ISO date',
      actualType: 'invalid date string',
    );
  }

  return DateTime(parsed.year, parsed.month, parsed.day);
}

String? normalizeOptionalCardLast4(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final normalized = normalizeCardLastFour(value);
  if (normalized.length != 4) {
    throw const MindeeFieldParseException(
      fieldName: 'card_last4',
      expectedType: 'exactly four digits',
      actualType: 'invalid card suffix',
    );
  }
  return normalized;
}

int toCents(double value) => (value * 100).round();

bool depositPaymentBreakdownMatches({
  required double totalAmount,
  required double creditDeposit,
  required double cash,
  required double giftCard,
  required double other,
}) {
  final paymentTotalCents =
      toCents(creditDeposit) +
      toCents(cash) +
      toCents(giftCard) +
      toCents(other);
  return paymentTotalCents == toCents(totalAmount);
}
