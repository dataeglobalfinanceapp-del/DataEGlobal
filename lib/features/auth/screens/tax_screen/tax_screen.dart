import 'package:flutter/material.dart';

import 'package:biztrack/services/app_clock.dart';
import 'package:biztrack/services/liability_service.dart';
import 'package:biztrack/services/money_formatter.dart';
import 'package:biztrack/services/recurrence_schedule.dart';

import 'tax_estimator.dart';

class TaxScreen extends StatefulWidget {
  final DateTimeRange? initialDateRange;

  const TaxScreen({super.key, this.initialDateRange});

  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  static const String _businessName = 'Save Tep';

  int _year = AppClock.now.year;
  late DateTimeRange _dateRange;
  bool _isLoading = true;
  List<DepositRecord> _deposits = [];
  List<ExpenseRecord> _expenses = [];

  @override
  void initState() {
    super.initState();
    _dateRange = _normalizedRange(widget.initialDateRange ?? _yearRange(_year));
    _year = _dateRange.start.year;
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
    final rangeStart = RecurrenceSchedule.dateOnly(_dateRange.start);
    final rangeEnd = RecurrenceSchedule.dateOnly(_dateRange.end);
    final rangeDeposits = _deposits
        .where(
          (record) =>
              _isInDateRange(record.transactionDate, rangeStart, rangeEnd),
        )
        .toList(growable: false);
    final grossIncome = rangeDeposits.fold<double>(
      0,
      (sum, record) => sum + record.totalAmount,
    );
    final expenseLines = _ProfitLossExpenseCatalog.buildLines(
      _expenses,
      dateRange: _dateRange,
    );
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
      periodStart: rangeStart,
      periodEnd: rangeEnd,
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
    setState(() {
      _year += delta;
      _dateRange = _yearRange(_year);
    });
  }

  Future<void> _selectDateRange() async {
    final firstDate = DateTime(_year - 5);
    final lastDate = DateTime(_year + 5, 12, 31);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: AppClock.now,
      initialDateRange: _dateRange,
      helpText: 'Select tax period',
      saveText: 'Apply',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _dateRange = _normalizedRange(picked);
      _year = _dateRange.start.year;
    });
  }

  static DateTimeRange _yearRange(int year) {
    return DateTimeRange(start: DateTime(year), end: DateTime(year, 12, 31));
  }

  static DateTimeRange _normalizedRange(DateTimeRange range) {
    final start = RecurrenceSchedule.dateOnly(range.start);
    final end = RecurrenceSchedule.dateOnly(range.end);
    if (end.isBefore(start)) {
      return DateTimeRange(start: end, end: start);
    }
    return DateTimeRange(start: start, end: end);
  }

  static bool _isInDateRange(DateTime value, DateTime start, DateTime end) {
    final date = RecurrenceSchedule.dateOnly(value);
    return !date.isBefore(start) && !date.isAfter(end);
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
                  const SizedBox(height: 8),
                  _DateRangeSelector(
                    range: _dateRange,
                    onPressed: _selectDateRange,
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
  static const _untrackedFill = Color(0xFFE0F2FE);
  static const Map<int, TableColumnWidth> _wideColumnWidths = {
    0: FlexColumnWidth(2.4),
    1: FlexColumnWidth(1),
  };
  static const Map<int, TableColumnWidth> _compactColumnWidths = {
    0: FlexColumnWidth(1.75),
    1: FlexColumnWidth(1),
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
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
    final isUntracked = !line.trackedInApp;
    final value = isUntracked && line.amount == 0
        ? ''
        : formatMoney(line.amount);

    return _row(
      label: line.label,
      value: value,
      fill: isUntracked ? _untrackedFill : null,
      labelSemanticLabel: isUntracked
          ? '${line.label}, not tracked in app'
          : null,
    );
  }

  static TableRow _row({
    required String label,
    String value = '',
    bool isBold = false,
    Color? fill,
    Color? labelColor,
    String? labelSemanticLabel,
  }) {
    return TableRow(
      decoration: BoxDecoration(color: fill),
      children: [
        _cell(
          label,
          isBold: isBold,
          color: labelColor,
          semanticLabel: labelSemanticLabel,
        ),
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

class _DateRangeSelector extends StatelessWidget {
  final DateTimeRange range;
  final VoidCallback onPressed;

  const _DateRangeSelector({required this.range, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final label =
        '${_ProfitAndTaxStatement._formatDate(range.start)} - '
        '${_ProfitAndTaxStatement._formatDate(range.end)}';

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('tax-date-range-button'),
            onPressed: onPressed,
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(label, textAlign: TextAlign.center),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
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
  final bool trackedInApp;

  const _ProfitLossExpenseLine({
    required this.label,
    required this.amount,
    required this.trackedInApp,
  });
}

class _ProfitLossExpenseDefinition {
  final String label;
  final List<String> categories;
  final bool trackedInApp;
  final bool includeUnmapped;
  final bool prorateFixedCost;

  const _ProfitLossExpenseDefinition(
    this.label, {
    this.categories = const <String>[],
    this.trackedInApp = false,
    this.includeUnmapped = false,
    this.prorateFixedCost = false,
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
      prorateFixedCost: true,
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
      prorateFixedCost: true,
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
      prorateFixedCost: true,
    ),
    _ProfitLossExpenseDefinition(
      'Other (excluding depreciation/amortization)',
      categories: <String>['Other'],
      includeUnmapped: true,
    ),
  ];

  static List<_ProfitLossExpenseLine> buildLines(
    List<ExpenseRecord> expenses, {
    required DateTimeRange dateRange,
  }) {
    final rangeStart = RecurrenceSchedule.dateOnly(dateRange.start);
    final rangeEndExclusive = RecurrenceSchedule.dateOnly(
      dateRange.end,
    ).add(const Duration(days: 1));
    final mappedCategories = definitions
        .where((definition) => !definition.includeUnmapped)
        .expand((definition) => definition.categories)
        .map(_normalize)
        .toSet();

    return definitions
        .map((definition) {
          final amount = definition.includeUnmapped
              ? _sumUnmappedExpenses(
                  expenses,
                  mappedCategories,
                  rangeStart,
                  rangeEndExclusive,
                )
              : _sumExpenses(
                  expenses,
                  definition.categories,
                  rangeStart,
                  rangeEndExclusive,
                  prorateFixedCost: definition.prorateFixedCost,
                );

          return _ProfitLossExpenseLine(
            label: definition.label,
            amount: amount,
            trackedInApp: definition.trackedInApp,
          );
        })
        .toList(growable: false);
  }

  static double _sumExpenses(
    List<ExpenseRecord> expenses,
    List<String> categories,
    DateTime rangeStart,
    DateTime rangeEndExclusive, {
    required bool prorateFixedCost,
  }) {
    if (!rangeStart.isBefore(rangeEndExclusive)) return 0;
    final categoryKeys = categories.map(_normalize).toSet();
    return expenses
        .where((record) => categoryKeys.contains(_normalize(record.category)))
        .fold<double>(
          0,
          (sum, record) =>
              sum +
              _expenseAmountForRange(
                record,
                rangeStart,
                rangeEndExclusive,
                expenses,
                prorateFixedCost: prorateFixedCost,
              ),
        );
  }

  static double _sumUnmappedExpenses(
    List<ExpenseRecord> expenses,
    Set<String> mappedCategories,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
  ) {
    if (!rangeStart.isBefore(rangeEndExclusive)) return 0;
    return expenses
        .where(
          (record) => !mappedCategories.contains(_normalize(record.category)),
        )
        .fold<double>(
          0,
          (sum, record) =>
              sum +
              _expenseAmountForRange(
                record,
                rangeStart,
                rangeEndExclusive,
                expenses,
                prorateFixedCost: _isFixedCostCategory(record.category),
              ),
        );
  }

  static double _expenseAmountForRange(
    ExpenseRecord expense,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
    List<ExpenseRecord> allExpenses, {
    required bool prorateFixedCost,
  }) {
    if (expense.isRecurring) {
      return _recurringExpenseAmountForRange(
        expense,
        rangeStart,
        rangeEndExclusive,
        allExpenses,
      );
    }
    if (prorateFixedCost) {
      return _monthlyFixedCostAmountForRange(
        expense,
        rangeStart,
        rangeEndExclusive,
      );
    }
    return _oneTimeExpenseAmountForRange(
      expense,
      rangeStart,
      rangeEndExclusive,
    );
  }

  static double _oneTimeExpenseAmountForRange(
    ExpenseRecord expense,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
  ) {
    final expenseDate = RecurrenceSchedule.dateOnly(expense.transactionDate);
    if (expenseDate.isBefore(rangeStart) ||
        !expenseDate.isBefore(rangeEndExclusive)) {
      return 0;
    }
    return expense.totalAmount;
  }

  static double _monthlyFixedCostAmountForRange(
    ExpenseRecord expense,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
  ) {
    final expenseDate = RecurrenceSchedule.dateOnly(expense.transactionDate);
    final periodStart = DateTime(expenseDate.year, expenseDate.month);
    final periodEndExclusive = DateTime(
      expenseDate.year,
      expenseDate.month + 1,
    );
    return _proratedAmountForOverlap(
      amount: expense.totalAmount,
      periodStart: periodStart,
      periodEndExclusive: periodEndExclusive,
      rangeStart: rangeStart,
      rangeEndExclusive: rangeEndExclusive,
    );
  }

  static double _recurringExpenseAmountForRange(
    ExpenseRecord expense,
    DateTime rangeStart,
    DateTime rangeEndExclusive,
    List<ExpenseRecord> allExpenses,
  ) {
    final periodStart = RecurrenceSchedule.dateOnly(expense.transactionDate);
    final periodEndExclusive = _recurringExpensePeriodEndExclusive(
      expense,
      allExpenses,
    );
    return _proratedAmountForOverlap(
      amount: expense.totalAmount,
      periodStart: periodStart,
      periodEndExclusive: periodEndExclusive,
      rangeStart: rangeStart,
      rangeEndExclusive: rangeEndExclusive,
    );
  }

  static double _proratedAmountForOverlap({
    required double amount,
    required DateTime periodStart,
    required DateTime periodEndExclusive,
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
  }) {
    final periodDays = periodEndExclusive.difference(periodStart).inDays;
    if (periodDays <= 0) return 0;

    final overlapStart = _laterDate(periodStart, rangeStart);
    final overlapEnd = _earlierDate(periodEndExclusive, rangeEndExclusive);
    final overlapDays = overlapEnd.difference(overlapStart).inDays;
    if (overlapDays <= 0) return 0;

    final dailyRate = amount / periodDays;
    return dailyRate * overlapDays;
  }

  static DateTime _recurringExpensePeriodEndExclusive(
    ExpenseRecord expense,
    List<ExpenseRecord> allExpenses,
  ) {
    final occurrenceDate = RecurrenceSchedule.dateOnly(expense.transactionDate);
    final frequency = expense.normalizedRecurringFrequency;
    final seriesStartDate = _recurringSeriesStartDate(expense, allExpenses);
    final searchThrough = _recurringSearchThrough(occurrenceDate, frequency);
    final dates = RecurrenceSchedule.dueDates(
      startDate: seriesStartDate,
      through: searchThrough,
      frequency: frequency,
    );

    for (final date in dates) {
      if (date.isAfter(occurrenceDate)) return date;
    }

    return _fallbackRecurringPeriodEnd(occurrenceDate, frequency);
  }

  static DateTime _recurringSeriesStartDate(
    ExpenseRecord expense,
    List<ExpenseRecord> allExpenses,
  ) {
    var startDate = RecurrenceSchedule.dateOnly(expense.transactionDate);
    for (final record in allExpenses) {
      if (record.recurringSeriesId != expense.recurringSeriesId) continue;
      final recordDate = RecurrenceSchedule.dateOnly(record.transactionDate);
      if (recordDate.isBefore(startDate)) startDate = recordDate;
    }
    return startDate;
  }

  static DateTime _recurringSearchThrough(DateTime date, String frequency) {
    return switch (frequency) {
      RecurrenceSchedule.weekly => date.add(const Duration(days: 14)),
      RecurrenceSchedule.biweekly => date.add(const Duration(days: 28)),
      RecurrenceSchedule.semiMonthly => _addMonthsClamped(date, 2),
      RecurrenceSchedule.quarterly => _addMonthsClamped(date, 6),
      RecurrenceSchedule.yearly => _addMonthsClamped(date, 24),
      _ => _addMonthsClamped(date, 2),
    };
  }

  static DateTime _fallbackRecurringPeriodEnd(DateTime date, String frequency) {
    return switch (frequency) {
      RecurrenceSchedule.weekly => date.add(const Duration(days: 7)),
      RecurrenceSchedule.biweekly => date.add(const Duration(days: 14)),
      RecurrenceSchedule.semiMonthly => date.add(const Duration(days: 15)),
      RecurrenceSchedule.quarterly => _addMonthsClamped(date, 3),
      RecurrenceSchedule.yearly => _addMonthsClamped(date, 12),
      _ => _addMonthsClamped(date, 1),
    };
  }

  static DateTime _addMonthsClamped(DateTime date, int months) {
    final totalMonths = date.year * 12 + date.month - 1 + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = date.day < daysInMonth ? date.day : daysInMonth;
    return DateTime(year, month, day);
  }

  static DateTime _laterDate(DateTime left, DateTime right) {
    return left.isAfter(right) ? left : right;
  }

  static DateTime _earlierDate(DateTime left, DateTime right) {
    return left.isBefore(right) ? left : right;
  }

  static bool _isFixedCostCategory(String value) {
    return switch (_normalize(value)) {
      'payroll' || 'rent' || 'utilities' => true,
      _ => false,
    };
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
