import 'package:flutter/material.dart';

import 'package:savetep/services/app_clock.dart';

class AppDateRangeSelector extends StatelessWidget {
  final DateTimeRange range;
  final ValueChanged<DateTimeRange> onRangeChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? currentDate;
  final String helpText;
  final String saveText;
  final String? tooltip;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final Color foregroundColor;
  final Color backgroundColor;
  final BorderSide borderSide;
  final List<BoxShadow> boxShadow;

  const AppDateRangeSelector({
    super.key,
    required this.range,
    required this.onRangeChanged,
    required this.firstDate,
    required this.lastDate,
    this.currentDate,
    this.helpText = 'Select date range',
    this.saveText = 'Apply',
    this.tooltip,
    this.maxWidth = 420,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.textStyle = const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    this.foregroundColor = const Color(0xFF111827),
    this.backgroundColor = Colors.white,
    this.borderSide = const BorderSide(color: Color(0xFFD1D5DB)),
    this.boxShadow = const <BoxShadow>[],
  });

  @override
  Widget build(BuildContext context) {
    final Widget button = OutlinedButton.icon(
      onPressed: () => _selectRange(context),
      icon: const Icon(Icons.date_range_outlined, size: 18),
      label: Text(labelFor(range), textAlign: TextAlign.center),
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        side: borderSide,
        padding: padding,
        textStyle: textStyle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    final Widget content = tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: boxShadow,
          ),
          child: content,
        ),
      ),
    );
  }

  Future<void> _selectRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: dateOnly(firstDate),
      lastDate: dateOnly(lastDate),
      currentDate: currentDate == null ? AppClock.now : dateOnly(currentDate!),
      initialDateRange: normalized(range),
      helpText: helpText,
      saveText: saveText,
    );
    if (picked == null) return;

    onRangeChanged(normalized(picked));
  }

  static String labelFor(DateTimeRange range) {
    final DateTimeRange normalizedRange = normalized(range);
    return '${formatDate(normalizedRange.start)} - '
        '${formatDate(normalizedRange.end)}';
  }

  static String formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static DateTimeRange normalized(DateTimeRange range) {
    final DateTime start = dateOnly(range.start);
    final DateTime end = dateOnly(range.end);
    if (end.isBefore(start)) {
      return DateTimeRange(start: end, end: start);
    }
    return DateTimeRange(start: start, end: end);
  }

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
