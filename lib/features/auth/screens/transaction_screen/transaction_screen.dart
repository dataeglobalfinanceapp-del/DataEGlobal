import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../services/app_clock.dart';
import '../../../../services/excel_transaction_report.dart';
import '../../../../services/exporter/file_exporter.dart';
import '../../../../services/liability_service.dart';
import '../../../../services/money_formatter.dart';
import '../../../../services/exporter/pdf_exporter.dart';
import '../../../../services/exporter/pdf_printer.dart';
import '../../../../services/yearly_pdf_report.dart';

enum _TransactionKind { deposit, expense }

enum _TransactionFilter { weekly, monthly, quarterly, yearly }

enum _ExportPeriod { week, month, year }

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  _TransactionKind _kind = _TransactionKind.deposit;
  _TransactionFilter _filter = _TransactionFilter.weekly;
  int _year = AppClock.now.year;
  String? _category;
  bool _isLoading = true;
  List<DepositRecord> _deposits = [];
  List<ExpenseRecord> _expenses = [];
  final Set<String> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
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

  double get _totalDeposits => _deposits
      .where((record) => record.transactionDate.year == _year)
      .fold(0, (total, record) => total + record.totalAmount);

  double get _totalExpenses => _expenses
      .where((record) => record.transactionDate.year == _year)
      .fold(0, (total, record) => total + record.totalAmount);

  List<String> get _expenseCategories {
    final categories = _expenses
        .map((record) => record.category)
        .where((category) => category.trim().isNotEmpty)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  List<_TransactionGroup> get _groups {
    if (_kind == _TransactionKind.deposit) {
      final records = _deposits
          .where((record) => record.transactionDate.year == _year)
          .toList();
      return _buildDepositGroups(records);
    }

    final records = _expenses.where((record) {
      final matchesYear = record.transactionDate.year == _year;
      final matchesCategory = _category == null || record.category == _category;
      return matchesYear && matchesCategory;
    }).toList();
    return _buildExpenseGroups(records);
  }

  void _setKind(_TransactionKind kind) {
    setState(() {
      _kind = kind;
      _expandedGroups.clear();
    });
  }

  void _setFilter(_TransactionFilter filter) {
    setState(() {
      _filter = filter;
      _expandedGroups.clear();
    });
  }

  void _changeYear(int delta) {
    setState(() {
      _year += delta;
      _expandedGroups.clear();
    });
  }

  void _toggleGroup(String key) {
    setState(() {
      if (_expandedGroups.contains(key)) {
        _expandedGroups.remove(key);
      } else {
        _expandedGroups.add(key);
      }
    });
  }

  Future<void> _chooseCategory() async {
    if (_kind != _TransactionKind.expense) return;
    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('All Categories'),
                trailing: _category == null
                    ? const Icon(Icons.check, color: Color(0xFF1A2340))
                    : null,
                onTap: () => Navigator.pop(context),
              ),
              ..._expenseCategories.map(
                (category) => ListTile(
                  title: Text(category),
                  trailing: category == _category
                      ? const Icon(Icons.check, color: Color(0xFF1A2340))
                      : null,
                  onTap: () => Navigator.pop(context, category),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _category = selected;
      _expandedGroups.clear();
    });
  }

  List<_TransactionGroup> _buildDepositGroups(List<DepositRecord> records) {
    return _groupRecords<DepositRecord>(
      records: records,
      dateOf: (record) => record.transactionDate,
      amountOf: (record) => record.totalAmount,
      itemBuilder: _depositItems,
    );
  }

  List<_TransactionGroup> _buildExpenseGroups(List<ExpenseRecord> records) {
    return _groupRecords<ExpenseRecord>(
      records: records,
      dateOf: (record) => record.transactionDate,
      amountOf: (record) => record.totalAmount,
      itemBuilder: (record) {
        final checkDetail =
            'Check #${record.checkNumber.isEmpty ? '-' : record.checkNumber}';
        return [
          _TransactionItem(
            id: record.id,
            kind: _TransactionKind.expense,
            title: record.payee.isEmpty ? record.category : record.payee,
            subtitle: record.category,
            date: record.transactionDate,
            amount: record.totalAmount,
            detail: record.isRecurring
                ? 'Monthly recurring | $checkDetail'
                : checkDetail,
            icon: record.isRecurring
                ? Icons.repeat
                : Icons.receipt_long_outlined,
            iconColor: record.isRecurring
                ? const Color(0xFF0F766E)
                : const Color(0xFFEF4444),
            isRecurring: record.isRecurring,
          ),
        ];
      },
    );
  }

  List<_TransactionItem> _depositItems(DepositRecord record) {
    final items = <_TransactionItem>[];
    void addMethod({
      required String label,
      required double amount,
      required IconData icon,
      required Color color,
    }) {
      if (amount <= 0) return;
      items.add(
        _TransactionItem(
          id: record.id,
          kind: _TransactionKind.deposit,
          title: label,
          subtitle: record.orderNumber.isEmpty
              ? record.isManual
                    ? 'Manual entry'
                    : 'Scanned receipt'
              : 'Order #${record.orderNumber}',
          date: record.transactionDate,
          amount: amount,
          detail: record.isManual ? 'Manual entry' : 'Scanned receipt',
          icon: icon,
          iconColor: color,
        ),
      );
    }

    addMethod(
      label: 'Credit/Debit',
      amount: record.creditDebt,
      icon: Icons.credit_card,
      color: const Color(0xFF2563EB),
    );
    addMethod(
      label: 'Cash',
      amount: record.cash,
      icon: Icons.payments_outlined,
      color: const Color(0xFF16A34A),
    );
    addMethod(
      label: 'Gift Card',
      amount: record.giftCard,
      icon: Icons.card_giftcard,
      color: const Color(0xFF0EA5E9),
    );
    addMethod(
      label: 'Other',
      amount: record.other,
      icon: Icons.account_balance_wallet_outlined,
      color: const Color(0xFFF59E0B),
    );

    if (items.isEmpty) {
      items.add(
        _TransactionItem(
          id: record.id,
          kind: _TransactionKind.deposit,
          title: 'Deposit',
          subtitle: record.orderNumber.isEmpty
              ? '-'
              : 'Order #${record.orderNumber}',
          date: record.transactionDate,
          amount: record.totalAmount,
          detail: record.isManual ? 'Manual entry' : 'Scanned receipt',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: const Color(0xFF16A34A),
        ),
      );
    }

    return items;
  }

  List<_TransactionGroup> _groupRecords<T>({
    required List<T> records,
    required DateTime Function(T record) dateOf,
    required double Function(T record) amountOf,
    required List<_TransactionItem> Function(T record) itemBuilder,
  }) {
    final buckets = <String, _MutableGroup<T>>{};

    for (final record in records) {
      final date = dateOf(record);
      final key = _groupKey(date);
      buckets.putIfAbsent(
        key,
        () => _MutableGroup<T>(key: key, title: _groupTitle(date)),
      );
      buckets[key]!.records.add(record);
      buckets[key]!.total += amountOf(record);
    }

    final groups = buckets.values.map((bucket) {
      bucket.records.sort((a, b) => dateOf(b).compareTo(dateOf(a)));
      return _TransactionGroup(
        key: bucket.key,
        title: bucket.title,
        total: bucket.total,
        items: bucket.records.expand(itemBuilder).toList(),
      );
    }).toList();

    groups.sort((a, b) => _sortKey(b.key).compareTo(_sortKey(a.key)));
    return groups;
  }

  String _groupKey(DateTime date) {
    return switch (_filter) {
      _TransactionFilter.weekly => '${date.year}-w${_weekOfYear(date)}',
      _TransactionFilter.monthly =>
        '${date.year}-${date.month.toString().padLeft(2, '0')}',
      _TransactionFilter.quarterly =>
        '${date.year}-q${((date.month - 1) ~/ 3) + 1}',
      _TransactionFilter.yearly => '${date.year}',
    };
  }

  String _groupTitle(DateTime date) {
    return switch (_filter) {
      _TransactionFilter.weekly => 'Week ${_weekOfYear(date)}',
      _TransactionFilter.monthly => _monthNames[date.month],
      _TransactionFilter.quarterly => 'Quarter ${((date.month - 1) ~/ 3) + 1}',
      _TransactionFilter.yearly => '${date.year}',
    };
  }

  int _sortKey(String key) {
    final digits = key.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  int _weekOfYear(DateTime date) {
    final firstDay = DateTime(date.year);
    return ((date.difference(firstDay).inDays + firstDay.weekday) / 7).ceil();
  }

  String _fmtMoney(double value) => formatMoney(value);

  Future<void> _confirmDeleteItem(_TransactionItem item) async {
    final kindLabel = item.kind == _TransactionKind.deposit
        ? 'deposit'
        : 'expense';
    final isRecurringExpense =
        item.kind == _TransactionKind.expense && item.isRecurring;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isRecurringExpense
              ? 'Delete recurring expense?'
              : 'Delete $kindLabel?',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('${_fmtFullDate(item.date)}  |  ${_fmtMoney(item.amount)}'),
            if (item.detail.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.detail,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
            if (isRecurringExpense) ...[
              const SizedBox(height: 10),
              const Text(
                'This will stop the recurring expense starting this month. Previous monthly entries will stay in history.',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deleted = item.kind == _TransactionKind.deposit
        ? await LiabilityService.deleteDeposit(item.id)
        : await LiabilityService.deleteExpense(item.id);

    if (!mounted) return;
    if (deleted) {
      await _loadTransactions();
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? isRecurringExpense
                    ? 'Recurring expense stopped for future months.'
                    : '${_capitalize(kindLabel)} deleted.'
              : 'Could not find that $kindLabel.',
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final range = await _chooseExportRange('Export PDF');
    if (range == null) return;

    final pdf = _buildTransactionPdf(range);
    final savedTo = await PdfExporter.savePdf(
      fileName: pdf.fileName,
      bytes: pdf.bytes,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF exported: $savedTo')));
  }

  Future<void> _printPdf() async {
    final range = await _chooseExportRange('Print PDF');
    if (range == null) return;

    final pdf = _buildTransactionPdf(range);
    try {
      final status = await PdfPrinter.printPdf(
        fileName: pdf.fileName,
        bytes: pdf.bytes,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF print: $status')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not print PDF: $error')));
    }
  }

  _TransactionPdfPayload _buildTransactionPdf(_ExportRange range) {
    final isDeposit = _kind == _TransactionKind.deposit;
    final rows = _reportRows(range);
    final total = rows.fold<double>(0, (sum, row) => sum + row.amount);
    final typeLabel = isDeposit ? 'Deposit' : 'Expense';
    final categoryLabel = !isDeposit && _category != null
        ? ' - $_category'
        : '';
    final bytes = YearlyTransactionPdfReport.build(
      reportTitle: '$typeLabel ${range.periodTitle} Report$categoryLabel',
      periodLabel: range.label,
      rows: rows,
      total: total,
    );
    final categoryPart = !isDeposit && _category != null
        ? '-${_slug(_category!)}'
        : '';
    final fileName =
        'FinApp-${typeLabel.toLowerCase()}s-${range.fileToken}$categoryPart.pdf';

    return _TransactionPdfPayload(fileName: fileName, bytes: bytes);
  }

  Future<void> _exportExcel() async {
    final range = await _chooseExportRange('Export Excel');
    if (range == null) return;

    final isDeposit = _kind == _TransactionKind.deposit;
    final rows = _reportRows(range);
    final total = rows.fold<double>(0, (sum, row) => sum + row.amount);
    final typeLabel = isDeposit ? 'Deposit' : 'Expense';
    final categoryLabel = !isDeposit && _category != null
        ? ' - $_category'
        : '';
    final bytes = ExcelTransactionReport.build(
      reportTitle: '$typeLabel ${range.periodTitle} Report$categoryLabel',
      periodLabel: range.label,
      transactionType: typeLabel,
      rows: rows,
      total: total,
    );
    final categoryPart = !isDeposit && _category != null
        ? '-${_slug(_category!)}'
        : '';
    final fileName =
        'FinApp-${typeLabel.toLowerCase()}s-${range.fileToken}$categoryPart.xls';

    final savedTo = await FileExporter.save(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/vnd.ms-excel',
    );
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Excel exported: $savedTo')));
  }

  Future<_ExportRange?> _chooseExportRange(String actionLabel) async {
    final period = await showModalBottomSheet<_ExportPeriod>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$actionLabel by',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _ExportPeriodTile(
              icon: Icons.calendar_view_week,
              title: 'Week',
              subtitle: 'Choose any day in the week',
              onTap: () => Navigator.pop(context, _ExportPeriod.week),
            ),
            _ExportPeriodTile(
              icon: Icons.calendar_month,
              title: 'Month',
              subtitle: 'Choose month and year',
              onTap: () => Navigator.pop(context, _ExportPeriod.month),
            ),
            _ExportPeriodTile(
              icon: Icons.event_available,
              title: 'Year',
              subtitle: 'Choose year only',
              onTap: () => Navigator.pop(context, _ExportPeriod.year),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (!mounted || period == null) return null;

    return switch (period) {
      _ExportPeriod.week => _chooseWeekExportRange(),
      _ExportPeriod.month => _chooseMonthExportRange(),
      _ExportPeriod.year => _chooseYearExportRange(),
    };
  }

  Future<_ExportRange?> _chooseWeekExportRange() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _initialExportDate(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Choose week in calendar',
    );
    if (!mounted || picked == null) return null;

    return _weekRange(picked);
  }

  Future<_ExportRange?> _chooseMonthExportRange() async {
    final initial = _initialExportDate();
    final selected = await _showMonthYearDialog(
      initialMonth: initial.month,
      initialYear: initial.year,
    );
    if (!mounted || selected == null) return null;

    return _monthRange(year: selected.year, month: selected.month);
  }

  Future<_ExportRange?> _chooseYearExportRange() async {
    final selectedYear = await _showYearDialog(
      initialYear: _initialExportDate().year,
    );
    if (!mounted || selectedYear == null) return null;

    return _yearRange(selectedYear);
  }

  Future<_MonthYear?> _showMonthYearDialog({
    required int initialMonth,
    required int initialYear,
  }) {
    var selectedMonth = initialMonth;
    var selectedYear = initialYear;

    return showDialog<_MonthYear>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Choose month'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonth,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Month'),
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text(_shortMonthNames[month]),
                      );
                    }),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedMonth = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: _exportYears
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedYear = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _MonthYear(month: selectedMonth, year: selectedYear),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<int?> _showYearDialog({required int initialYear}) {
    var selectedYear = initialYear;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Choose year'),
              content: DropdownButtonFormField<int>(
                initialValue: selectedYear,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Year'),
                items: _exportYears
                    .map(
                      (year) =>
                          DropdownMenuItem(value: year, child: Text('$year')),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => selectedYear = value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selectedYear),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  DateTime _initialExportDate() {
    final now = AppClock.now;
    final safeYear = _year.clamp(2000, 2100).toInt();
    if (safeYear == now.year) {
      return DateTime(safeYear, now.month, now.day);
    }
    return DateTime(safeYear);
  }

  List<int> get _exportYears => List.generate(101, (index) => 2000 + index);

  _ExportRange _weekRange(DateTime picked) {
    final day = _dateOnly(picked);
    final start = day.subtract(Duration(days: day.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return _ExportRange(
      period: _ExportPeriod.week,
      start: start,
      end: end,
      label: '${_fmtFullDate(start)} - ${_fmtFullDate(end)}',
      fileToken: '${_dateToken(start)}-to-${_dateToken(end)}',
    );
  }

  _ExportRange _monthRange({required int year, required int month}) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1, 0);
    return _ExportRange(
      period: _ExportPeriod.month,
      start: start,
      end: end,
      label: '${_monthNames[month]} $year',
      fileToken: '$year-${month.toString().padLeft(2, '0')}',
    );
  }

  _ExportRange _yearRange(int year) {
    final start = DateTime(year);
    final end = DateTime(year, 12, 31);
    return _ExportRange(
      period: _ExportPeriod.year,
      start: start,
      end: end,
      label: '$year',
      fileToken: '$year',
    );
  }

  List<TransactionReportRow> _reportRows(_ExportRange range) {
    return _kind == _TransactionKind.deposit
        ? _depositReportRows(range)
        : _expenseReportRows(range);
  }

  List<TransactionReportRow> _depositReportRows(_ExportRange range) {
    final records =
        _deposits
            .where((record) => _isInRange(record.transactionDate, range))
            .toList()
          ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    return records
        .map(
          (record) => TransactionReportRow(
            date: record.transactionDate,
            title: 'Order #${record.orderNumber}',
            category: 'Deposit',
            amount: record.totalAmount,
            detail:
                'Cash ${_fmtMoney(record.cash)}, Credit ${_fmtMoney(record.creditDebt)}, Gift ${_fmtMoney(record.giftCard)}, Other ${_fmtMoney(record.other)}',
          ),
        )
        .toList();
  }

  List<TransactionReportRow> _expenseReportRows(_ExportRange range) {
    final records = _expenses.where((record) {
      final matchesRange = _isInRange(record.transactionDate, range);
      final matchesCategory = _category == null || record.category == _category;
      return matchesRange && matchesCategory;
    }).toList()..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    return records
        .map(
          (record) => TransactionReportRow(
            date: record.transactionDate,
            title: record.payee.isEmpty ? record.category : record.payee,
            category: record.category,
            amount: record.totalAmount,
            detail: record.isRecurring
                ? 'Monthly recurring | Check #${record.checkNumber.isEmpty ? '-' : record.checkNumber}'
                : 'Check #${record.checkNumber.isEmpty ? '-' : record.checkNumber}',
          ),
        )
        .toList();
  }

  bool _isInRange(DateTime value, _ExportRange range) {
    final date = _dateOnly(value);
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _dateToken(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _fmtFullDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final reserves = _totalDeposits - _totalExpenses;
    final groups = _groups;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Transaction',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Color(0xFF1E40AF)),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _SummaryPanel(
                    totalDeposits: _totalDeposits,
                    totalExpenses: _totalExpenses,
                    totalReserves: reserves,
                    fmtMoney: _fmtMoney,
                  ),
                  const SizedBox(height: 10),
                  _KindToggle(kind: _kind, onChanged: _setKind),
                  const SizedBox(height: 10),
                  _CategorySelector(
                    enabled: _kind == _TransactionKind.expense,
                    label: _category ?? 'Category',
                    onTap: _chooseCategory,
                  ),
                  const SizedBox(height: 10),
                  _FilterBar(filter: _filter, onChanged: _setFilter),
                  const SizedBox(height: 12),
                  _YearSelector(
                    year: _year,
                    onPrev: () => _changeYear(-1),
                    onNext: () => _changeYear(1),
                  ),
                  const SizedBox(height: 12),
                  if (groups.isEmpty)
                    _EmptyTransactions(kind: _kind)
                  else
                    ...groups.map(
                      (group) => _TransactionGroupTile(
                        group: group,
                        isExpanded: _expandedGroups.contains(group.key),
                        onToggle: () => _toggleGroup(group.key),
                        fmtMoney: _fmtMoney,
                        isExpense: _kind == _TransactionKind.expense,
                        onDelete: _confirmDeleteItem,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ExportButton(
                          icon: Icons.picture_as_pdf,
                          label: 'PDF',
                          color: const Color(0xFFEF4444),
                          onTap: _exportPdf,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ExportButton(
                          icon: Icons.print_outlined,
                          label: 'Print',
                          color: const Color(0xFF1E40AF),
                          onTap: _printPdf,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ExportButton(
                          icon: Icons.table_chart,
                          label: 'Excel',
                          color: const Color(0xFF16A34A),
                          onTap: _exportExcel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final double totalDeposits;
  final double totalExpenses;
  final double totalReserves;
  final String Function(double value) fmtMoney;

  const _SummaryPanel({
    required this.totalDeposits,
    required this.totalExpenses,
    required this.totalReserves,
    required this.fmtMoney,
  });

  @override
  Widget build(BuildContext context) {
    final reservesColor = totalReserves > 0
        ? const Color(0xFF16A34A)
        : const Color(0xFFFF1744);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171638),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: _SummaryLabel(label: 'TOTAL RESERVES')),
              Text(
                fmtMoney(totalReserves),
                style: TextStyle(
                  color: reservesColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'TOTAL EXPENSE',
                  value: fmtMoney(totalExpenses),
                  color: const Color(0xFFFF1744),
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  label: 'TOTAL DEPOSIT',
                  value: fmtMoney(totalDeposits),
                  color: const Color(0xFF00D26A),
                  alignRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryLabel extends StatelessWidget {
  final String label;

  const _SummaryLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignRight;

  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        _SummaryLabel(label: label),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _KindToggle extends StatelessWidget {
  final _TransactionKind kind;
  final ValueChanged<_TransactionKind> onChanged;

  const _KindToggle({required this.kind, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _ToggleButton(
            label: 'Deposit',
            isActive: kind == _TransactionKind.deposit,
            onTap: () => onChanged(_TransactionKind.deposit),
          ),
          _ToggleButton(
            label: 'Expense',
            isActive: kind == _TransactionKind.expense,
            onTap: () => onChanged(_TransactionKind.expense),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF171638) : Colors.white,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  const _CategorySelector({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.chevron_right,
              size: 18,
              color: enabled ? Colors.black54 : Colors.black26,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                enabled ? label : 'Category',
                style: TextStyle(
                  color: enabled ? Colors.black87 : Colors.black38,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.grid_view, color: Color(0xFF3B82F6), size: 20),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _TransactionFilter filter;
  final ValueChanged<_TransactionFilter> onChanged;

  const _FilterBar({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const filters = [
      (_TransactionFilter.weekly, 'Weekly'),
      (_TransactionFilter.monthly, 'Monthly'),
      (_TransactionFilter.quarterly, 'Quarterly'),
      (_TransactionFilter.yearly, 'Yearly'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: filters.map((entry) {
          final isActive = filter == entry.$1;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(entry.$1),
              borderRadius: BorderRadius.circular(3),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF171638) : Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  entry.$2,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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

class _TransactionGroupTile extends StatelessWidget {
  final _TransactionGroup group;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String Function(double value) fmtMoney;
  final bool isExpense;
  final ValueChanged<_TransactionItem> onDelete;

  const _TransactionGroupTile({
    required this.group,
    required this.isExpanded,
    required this.onToggle,
    required this.fmtMoney,
    required this.isExpense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.chevron_right,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    fmtMoney(group.total),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const _TransactionTableHeader(),
            ...group.items.map(
              (item) => Column(
                children: [
                  _TransactionItemRow(
                    item: item,
                    isExpense: isExpense,
                    fmtMoney: fmtMoney,
                    onDelete: () => onDelete(item),
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionTableHeader extends StatelessWidget {
  const _TransactionTableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 9, 10, 7),
      child: Row(
        children: [
          SizedBox(width: 42, child: _TableHeaderText('DATE')),
          SizedBox(width: 8),
          Expanded(child: _TableHeaderText('DESCRIPTION')),
          SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: _TableHeaderText('AMOUNT', textAlign: TextAlign.right),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: _TableHeaderText('METHOD', textAlign: TextAlign.center),
          ),
          SizedBox(width: 4),
          SizedBox(
            width: 30,
            child: Icon(
              Icons.delete_outline,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String label;
  final TextAlign textAlign;

  const _TableHeaderText(this.label, {this.textAlign = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _TransactionItemRow extends StatelessWidget {
  final _TransactionItem item;
  final bool isExpense;
  final String Function(double value) fmtMoney;
  final VoidCallback onDelete;

  const _TransactionItemRow({
    required this.item,
    required this.isExpense,
    required this.fmtMoney,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 42,
            child: Text(
              _shortDate(item.date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                fmtMoney(item.amount),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isExpense
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF111827),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox.square(
            dimension: 34,
            child: Center(
              child: Icon(item.icon, size: 18, color: item.iconColor),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox.square(
            dimension: 30,
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Delete',
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Color(0xFFDC2626),
              ),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';
}

class _EmptyTransactions extends StatelessWidget {
  final _TransactionKind kind;

  const _EmptyTransactions({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Icon(
            kind == _TransactionKind.deposit
                ? Icons.account_balance_wallet_outlined
                : Icons.receipt_long_outlined,
            color: const Color(0xFF9CA3AF),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            kind == _TransactionKind.deposit
                ? 'No deposit history for this view.'
                : 'No expense history for this view.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportPeriodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportPeriodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1E40AF)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MutableGroup<T> {
  final String key;
  final String title;
  final List<T> records = [];
  double total = 0;

  _MutableGroup({required this.key, required this.title});
}

class _TransactionGroup {
  final String key;
  final String title;
  final double total;
  final List<_TransactionItem> items;

  const _TransactionGroup({
    required this.key,
    required this.title,
    required this.total,
    required this.items,
  });
}

class _TransactionItem {
  final String id;
  final _TransactionKind kind;
  final String title;
  final String subtitle;
  final DateTime date;
  final double amount;
  final String detail;
  final IconData icon;
  final Color iconColor;
  final bool isRecurring;

  const _TransactionItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    required this.detail,
    required this.icon,
    required this.iconColor,
    this.isRecurring = false,
  });
}

class _TransactionPdfPayload {
  final String fileName;
  final Uint8List bytes;

  const _TransactionPdfPayload({required this.fileName, required this.bytes});
}

class _ExportRange {
  final _ExportPeriod period;
  final DateTime start;
  final DateTime end;
  final String label;
  final String fileToken;

  const _ExportRange({
    required this.period,
    required this.start,
    required this.end,
    required this.label,
    required this.fileToken,
  });

  String get periodTitle {
    return switch (period) {
      _ExportPeriod.week => 'Weekly',
      _ExportPeriod.month => 'Monthly',
      _ExportPeriod.year => 'Yearly',
    };
  }
}

class _MonthYear {
  final int month;
  final int year;

  const _MonthYear({required this.month, required this.year});
}

const _shortMonthNames = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _monthNames = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
