import 'package:flutter/material.dart';

import 'package:savetep/features/auth/widgets/expense_category_report_link.dart';
import 'package:savetep/services/money_formatter.dart';

import '../models/profit_loss_models.dart';

class ProfitLossStatement extends StatelessWidget {
  final ProfitLossReport report;

  const ProfitLossStatement({super.key, required this.report});

  static const Color _borderColor = Color(0xFF111827);
  static const Color _headerFill = Color(0xFFE5E7EB);
  static const Color _untrackedFill = Color(0xFFE0F2FE);
  static const Map<int, TableColumnWidth> _wideColumnWidths =
      <int, TableColumnWidth>{0: FlexColumnWidth(2.4), 1: FlexColumnWidth(1)};
  static const Map<int, TableColumnWidth> _compactColumnWidths =
      <int, TableColumnWidth>{0: FlexColumnWidth(1.75), 1: FlexColumnWidth(1)};

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 380;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _borderColor),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Profit and Loss Statement ${report.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Table(
                    border: TableBorder.all(color: _borderColor, width: 0.8),
                    columnWidths: isCompact
                        ? _compactColumnWidths
                        : _wideColumnWidths,
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: <TableRow>[
                      _infoRow('Period Start', _formatDate(report.periodStart)),
                      _infoRow('Period End', _formatDate(report.periodEnd)),
                      _infoRow('Business Name', report.businessName),
                      _sectionRow('GROSS INCOME'),
                      _amountRow('Gross Income', report.grossIncome),
                      _totalRow('Total Gross Income', report.grossIncome),
                      _sectionRow('DETAILED EXPENSES'),
                      for (final ProfitLossExpenseLine line
                          in report.expenseLines)
                        _expenseRow(line),
                      _totalRow('Total Expenses', report.totalExpenses),
                      _sectionRow('NET INCOME'),
                      _totalRow(
                        'Net Income Before Taxes',
                        report.netIncomeBeforeTaxes,
                      ),
                      _textValueRow(
                        'Estimated Tax Percentage',
                        '${report.estimatedTaxPercentage.toStringAsFixed(0)}%',
                      ),
                      _totalRow(
                        'Estimated Tax Amount',
                        report.estimatedTaxAmount,
                      ),
                      _grandTotalRow(
                        'Net Income After Taxes',
                        report.netIncomeAfterTaxes,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  static TableRow _infoRow(String label, String value) {
    return _row(label: label, value: value);
  }

  static TableRow _sectionRow(String label) {
    return _row(
      label: label,
      isBold: true,
      fill: _headerFill,
      labelColor: const Color(0xFF111827),
    );
  }

  static TableRow _amountRow(String label, double amount) {
    return _row(label: label, value: formatMoney(amount));
  }

  static TableRow _textValueRow(String label, String value) {
    return _row(label: label, value: value);
  }

  static TableRow _totalRow(String label, double amount) {
    return _row(label: label, value: formatMoney(amount), isBold: true);
  }

  static TableRow _grandTotalRow(String label, double amount) {
    return _row(
      label: label,
      value: formatMoney(amount),
      isBold: true,
      fill: const Color(0xFFF9FAFB),
    );
  }

  static TableRow _expenseRow(ProfitLossExpenseLine line) {
    final bool isUntracked = !line.trackedInApp;
    final String value = isUntracked && line.amount == 0
        ? ''
        : formatMoney(line.amount);
    final String? category = line.reportCategory;
    const TextStyle labelStyle = TextStyle(
      color: Color(0xFF111827),
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    return _row(
      label: line.label,
      labelChild: category == null || line.amount <= 0
          ? null
          : ExpenseCategoryReportLink(
              category: category,
              label: line.label,
              dateRange: DateTimeRange(
                start: line.periodStart,
                end: line.periodEnd,
              ),
              style: labelStyle,
              maxLines: 2,
            ),
      value: value,
      fill: isUntracked ? _untrackedFill : null,
      labelSemanticLabel: isUntracked
          ? '${line.label}, not tracked in app'
          : null,
    );
  }

  static TableRow _row({
    required String label,
    Widget? labelChild,
    String value = '',
    bool isBold = false,
    Color? fill,
    Color? labelColor,
    String? labelSemanticLabel,
  }) {
    return TableRow(
      decoration: BoxDecoration(color: fill),
      children: <Widget>[
        labelChild == null
            ? _cell(
                label,
                isBold: isBold,
                color: labelColor,
                semanticLabel: labelSemanticLabel,
              )
            : _cellChild(labelChild),
        _cell(value, alignRight: true, isBold: isBold),
      ],
    );
  }

  static Widget _cell(
    String text, {
    bool alignRight = false,
    bool isBold = false,
    Color? color,
    String? semanticLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        semanticsLabel: semanticLabel,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: color ?? const Color(0xFF111827),
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
        ),
      ),
    );
  }

  static Widget _cellChild(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}
