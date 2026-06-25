import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:biztrack/services/app_clock.dart';
import 'package:biztrack/services/liability_service.dart';
import 'package:biztrack/services/money_formatter.dart';

import 'tax_estimator.dart';

class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key});

  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  static const String _businessName = 'Save Tep';

  int _year = AppClock.now.year;
  bool _isLoading = true;
  List<DepositRecord> _deposits = [];
  List<ExpenseRecord> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final deposits = await LiabilityService.loadDeposits();
    final expenses = await LiabilityService.loadExpenses();
    if (!mounted) return;
    setState(() {
      _deposits = deposits;
      _expenses = expenses;
      _isLoading = false;
    });
  }

  int get _taxProjectionMonth {
    final now = AppClock.now;
    return _year == now.year ? now.month : 12;
  }

  _ProfitLossReport get _report {
    final yearDeposits = _deposits
        .where((record) => record.transactionDate.year == _year)
        .toList(growable: false);
    final yearExpenses = _expenses
        .where((record) => record.transactionDate.year == _year)
        .toList(growable: false);
    final grossIncome = yearDeposits.fold<double>(
      0,
      (sum, record) => sum + record.totalAmount,
    );
    final expenseLines = _ProfitLossExpenseCatalog.buildLines(yearExpenses);
    final totalExpenses = expenseLines.fold<double>(
      0,
      (sum, line) => sum + line.amount,
    );
    final netIncomeBeforeTaxes = grossIncome - totalExpenses;
    final estimate = TaxEstimator.calculate(
      totalReserve: netIncomeBeforeTaxes,
      currentMonth: _taxProjectionMonth,
    );

    return _ProfitLossReport(
      year: _year,
      periodStart: DateTime(_year),
      periodEnd: DateTime(_year, 12, 31),
      businessName: _businessName,
      grossIncome: grossIncome,
      expenseLines: expenseLines,
      totalExpenses: totalExpenses,
      netIncomeBeforeTaxes: netIncomeBeforeTaxes,
      estimatedTaxPercentage: estimate.bracket.rate,
      estimatedTaxAmount: estimate.taxDue,
      netIncomeAfterTaxes: estimate.remaining,
    );
  }

  void _changeYear(int delta) {
    setState(() => _year += delta);
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profit and Tax',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                children: [
                  _YearSelector(
                    year: _year,
                    onPrev: () => _changeYear(-1),
                    onNext: () => _changeYear(1),
                  ),
                  const SizedBox(height: 12),
                  _ProfitAndTaxStatement(report: report),
                ],
              ),
      ),
    );
  }
}

class _ProfitAndTaxStatement extends StatelessWidget {
  final _ProfitLossReport report;

  const _ProfitAndTaxStatement({required this.report});

  static const _borderColor = Color(0xFF111827);
  static const _headerFill = Color(0xFFE5E7EB);
  static const _commentFill = Color(0xFFFFF7ED);
  static const _commentText = Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(constraints.maxWidth, 640.0);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Profit and Loss Statement ${report.year}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Table(
                    border: TableBorder.all(color: _borderColor, width: 0.8),
                    columnWidths: const {
                      0: FlexColumnWidth(2.6),
                      1: FlexColumnWidth(1.45),
                      2: FlexColumnWidth(1.45),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      _infoRow('Period Start', _formatDate(report.periodStart)),
                      _infoRow('Period End', _formatDate(report.periodEnd)),
                      _infoRow('Business Name', report.businessName),
                      _sectionRow('GROSS INCOME'),
                      _amountRow('Gross Income', report.grossIncome),
                      _totalRow('Total Gross Income', report.grossIncome),
                      _sectionRow('DETAILED EXPENSES'),
                      for (final line in report.expenseLines) _expenseRow(line),
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

  static TableRow _expenseRow(_ProfitLossExpenseLine line) {
    final showComment = line.comment != null;
    final value = showComment && line.amount == 0
        ? ''
        : formatMoney(line.amount);

    return _row(
      label: line.label,
      comment: line.comment,
      value: value,
      commentFill: showComment ? _commentFill : null,
      commentColor: showComment ? _commentText : null,
    );
  }

  static TableRow _row({
    required String label,
    String? comment,
    String value = '',
    bool isBold = false,
    Color? fill,
    Color? labelColor,
    Color? commentFill,
    Color? commentColor,
  }) {
    return TableRow(
      decoration: BoxDecoration(color: fill),
      children: [
        _cell(label, isBold: isBold, color: labelColor),
        _cell(
          comment ?? '',
          background: commentFill,
          color: commentColor,
          isComment: comment != null,
        ),
        _cell(value, alignRight: true, isBold: isBold),
      ],
    );
  }

  static Widget _cell(
    String text, {
    bool alignRight = false,
    bool isBold = false,
    bool isComment = false,
    Color? background,
    Color? color,
  }) {
    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: color ?? const Color(0xFF111827),
          fontSize: isComment ? 11 : 12,
          fontStyle: isComment ? FontStyle.italic : FontStyle.normal,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _YearSelector({
    required this.year,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, size: 20),
        ),
        Text(
          '$year',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}

class _ProfitLossReport {
  final int year;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String businessName;
  final double grossIncome;
  final List<_ProfitLossExpenseLine> expenseLines;
  final double totalExpenses;
  final double netIncomeBeforeTaxes;
  final double estimatedTaxPercentage;
  final double estimatedTaxAmount;
  final double netIncomeAfterTaxes;

  const _ProfitLossReport({
    required this.year,
    required this.periodStart,
    required this.periodEnd,
    required this.businessName,
    required this.grossIncome,
    required this.expenseLines,
    required this.totalExpenses,
    required this.netIncomeBeforeTaxes,
    required this.estimatedTaxPercentage,
    required this.estimatedTaxAmount,
    required this.netIncomeAfterTaxes,
  });
}

class _ProfitLossExpenseLine {
  final String label;
  final double amount;
  final String? comment;

  const _ProfitLossExpenseLine({
    required this.label,
    required this.amount,
    this.comment,
  });
}

class _ProfitLossExpenseDefinition {
  final String label;
  final List<String> categories;
  final bool trackedInApp;
  final bool includeUnmapped;

  const _ProfitLossExpenseDefinition(
    this.label, {
    this.categories = const <String>[],
    this.trackedInApp = false,
    this.includeUnmapped = false,
  });
}

class _ProfitLossExpenseCatalog {
  const _ProfitLossExpenseCatalog._();

  static const List<_ProfitLossExpenseDefinition> definitions = [
    _ProfitLossExpenseDefinition(
      'Cost of Goods Sold (COGS)',
      categories: <String>['COGS'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition(
      'Accounting and Legal Fees',
      categories: <String>['Accounting and Legal Fees'],
    ),
    _ProfitLossExpenseDefinition(
      'Advertising',
      categories: <String>['Advertising'],
    ),
    _ProfitLossExpenseDefinition(
      'Insurance',
      categories: <String>['Insurance'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition(
      'Maintenance and Repairs',
      categories: <String>['Maintenance and Repairs'],
    ),
    _ProfitLossExpenseDefinition(
      'Consumable Supplies',
      categories: <String>['Consumable Supplies'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition(
      'Payroll',
      categories: <String>['Payroll'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition(
      'Equipment',
      categories: <String>['Equipment'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition(
      'Fuel',
      categories: <String>['Fuel'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition('Postage', categories: <String>['Postage']),
    _ProfitLossExpenseDefinition(
      'Rent',
      categories: <String>['Rent'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition('Licenses', categories: <String>['Licenses']),
    _ProfitLossExpenseDefinition('Taxes', categories: <String>['Taxes']),
    _ProfitLossExpenseDefinition(
      'Telephone',
      categories: <String>['Telephone'],
    ),
    _ProfitLossExpenseDefinition(
      'Travel/Transportation',
      categories: <String>['Travel/Transportation'],
    ),
    _ProfitLossExpenseDefinition(
      'Utilities',
      categories: <String>['Utilities'],
      trackedInApp: true,
    ),
    _ProfitLossExpenseDefinition(
      'Other (excluding depreciation/amortization)',
      categories: <String>['Other'],
      includeUnmapped: true,
    ),
  ];

  static List<_ProfitLossExpenseLine> buildLines(List<ExpenseRecord> expenses) {
    final mappedCategories = definitions
        .where((definition) => !definition.includeUnmapped)
        .expand((definition) => definition.categories)
        .map(_normalize)
        .toSet();

    return definitions
        .map((definition) {
          final amount = definition.includeUnmapped
              ? _sumUnmappedExpenses(expenses, mappedCategories)
              : _sumExpenses(expenses, definition.categories);
          final comment = !definition.trackedInApp && amount == 0
              ? 'Not tracked in app'
              : null;

          return _ProfitLossExpenseLine(
            label: definition.label,
            amount: amount,
            comment: comment,
          );
        })
        .toList(growable: false);
  }

  static double _sumExpenses(
    List<ExpenseRecord> expenses,
    List<String> categories,
  ) {
    final categoryKeys = categories.map(_normalize).toSet();
    return expenses
        .where((record) => categoryKeys.contains(_normalize(record.category)))
        .fold<double>(0, (sum, record) => sum + record.totalAmount);
  }

  static double _sumUnmappedExpenses(
    List<ExpenseRecord> expenses,
    Set<String> mappedCategories,
  ) {
    return expenses
        .where(
          (record) => !mappedCategories.contains(_normalize(record.category)),
        )
        .fold<double>(0, (sum, record) => sum + record.totalAmount);
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
