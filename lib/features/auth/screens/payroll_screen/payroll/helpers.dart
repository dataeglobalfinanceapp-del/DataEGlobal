part of '../payroll_screen.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime? _parseDate(String value) {
  final List<String> parts = value.split('/');
  if (parts.length != 3) return null;

  final int? month = int.tryParse(parts[0]);
  final int? day = int.tryParse(parts[1]);
  final int? year = int.tryParse(parts[2]);
  if (month == null || day == null || year == null) return null;

  return DateTime(year, month, day);
}

String _formatDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}
