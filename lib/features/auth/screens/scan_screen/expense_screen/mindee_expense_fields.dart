import 'package:flutter/foundation.dart';

import '../mindee/mindee_analysis_models.dart';

abstract final class MindeeExpenseFields {
  static const String supplierName = 'supplier_name';
  static const String date = 'date';
  static const String time = 'time';
  static const String totalAmount = 'total_amount';
  static const String tipsGratuity = 'tips_gratuity';
  static const String purchaseCategory = 'purchase_category';
  static const String cardLast4 = 'card_last4';
}

class ParsedTime {
  final int hour;
  final int minute;
  final int second;

  const ParsedTime({required this.hour, required this.minute, this.second = 0});
}

ParsedTime? parseOptionalMindeeTime(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final normalized = value.trim();
  final twentyFourHour = RegExp(
    r'^([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$',
  ).firstMatch(normalized);
  if (twentyFourHour != null) {
    return ParsedTime(
      hour: int.parse(twentyFourHour.group(1)!),
      minute: int.parse(twentyFourHour.group(2)!),
      second: int.tryParse(twentyFourHour.group(3) ?? '') ?? 0,
    );
  }

  final twelveHour = RegExp(
    r'^(0?[1-9]|1[0-2]):([0-5]\d)(?::([0-5]\d))?\s*([AaPp][Mm])$',
  ).firstMatch(normalized);
  if (twelveHour != null) {
    final period = twelveHour.group(4)!.toLowerCase();
    var hour = int.parse(twelveHour.group(1)!);
    if (period == 'am' && hour == 12) hour = 0;
    if (period == 'pm' && hour != 12) hour += 12;
    return ParsedTime(
      hour: hour,
      minute: int.parse(twelveHour.group(2)!),
      second: int.tryParse(twelveHour.group(3) ?? '') ?? 0,
    );
  }

  throw const MindeeFieldParseException(
    fieldName: MindeeExpenseFields.time,
    expectedType: 'HH:mm, HH:mm:ss, or h:mm AM/PM',
    actualType: 'invalid time string',
  );
}

DateTime parseMindeeExpenseDateTime({
  required String? dateValue,
  required String? timeValue,
  required DateTime fallback,
}) {
  if (dateValue == null || dateValue.trim().isEmpty) return fallback;

  final date = DateTime.tryParse(dateValue.trim());
  if (date == null) {
    throw const MindeeFieldParseException(
      fieldName: MindeeExpenseFields.date,
      expectedType: 'ISO date',
      actualType: 'invalid date string',
    );
  }

  ParsedTime? parsedTime;
  try {
    parsedTime = parseOptionalMindeeTime(timeValue);
  } on MindeeFieldParseException catch (error) {
    debugPrint(
      'Mindee field "${error.fieldName}" was not applied: '
      'expected ${error.expectedType}, received ${error.actualType}.',
    );
  }

  return DateTime(
    date.year,
    date.month,
    date.day,
    parsedTime?.hour ?? 0,
    parsedTime?.minute ?? 0,
    parsedTime?.second ?? 0,
  );
}

DateTime replaceDateOnly(DateTime current, DateTime selectedDate) {
  return DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    current.hour,
    current.minute,
    current.second,
  );
}
