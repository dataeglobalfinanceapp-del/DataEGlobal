import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:savetep/features/auth/models/balance_summary_data.dart';
import 'package:savetep/features/auth/widgets/balance_summary_card.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/excel_transaction_report.dart';
import 'package:savetep/services/exporter/file_exporter.dart';
import 'package:savetep/services/exporter/pdf_exporter.dart';
import 'package:savetep/services/exporter/pdf_printer.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/money_formatter.dart';
import 'package:savetep/services/tax_estimate_service.dart';
import 'package:savetep/services/yearly_pdf_report.dart';

import '../../widgets/app_date_range_selector.dart';
import '../../widgets/expense_category_link.dart';

part 'transaction_controller.dart';
part 'transaction_models.dart';
part 'transaction_widgets.dart';

class TransactionScreenArguments {
  final DateTimeRange? initialExpenseDateRange;
  final String? initialExpenseCategory;

  const TransactionScreenArguments({
    this.initialExpenseDateRange,
    this.initialExpenseCategory,
  });
}

class TransactionScreen extends StatefulWidget {
  final DateTimeRange? initialExpenseDateRange;
  final String? initialExpenseCategory;

  const TransactionScreen({
    super.key,
    this.initialExpenseDateRange,
    this.initialExpenseCategory,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  late final _TransactionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _TransactionController(
      initialExpenseDateRange: widget.initialExpenseDateRange,
      initialExpenseCategory: widget.initialExpenseCategory,
    )..loadTransactions();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chooseCategory() async {
    final _TransactionViewState state = _controller.state;
    if (state.kind != _TransactionKind.expense) return;

    final String? selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: _TransactionTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) {
        return _CategoryBottomSheet(
          categories: state.expenseCategories,
          selectedCategory: state.category,
        );
      },
    );
    if (!mounted) return;

    _controller.setCategory(selected);
  }

  Future<void> _confirmDeleteItem(_TransactionItem item) async {
    final String kindLabel = item.kind.label;
    final bool isRecurringExpense =
        item.kind == _TransactionKind.expense && item.isRecurring;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return _DeleteTransactionDialog(
          item: item,
          kindLabel: kindLabel,
          isRecurringExpense: isRecurringExpense,
        );
      },
    );

    if (confirmed != true) return;

    final bool deleted = await _controller.deleteItem(item);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? isRecurringExpense
                    ? 'Recurring expense stopped for future months.'
                    : '${_TransactionDateUtils.capitalize(kindLabel)} deleted.'
              : 'Could not find that $kindLabel.',
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final _ExportRange? range = await _chooseExportRange('Export PDF');
    if (range == null) return;

    final String savedTo = await _controller.exportPdf(range);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF exported: $savedTo')));
  }

  Future<void> _printPdf() async {
    final _ExportRange? range = await _chooseExportRange('Print PDF');
    if (range == null) return;

    try {
      final String status = await _controller.printPdf(range);
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

  Future<void> _exportExcel() async {
    final _ExportRange? range = await _chooseExportRange('Export Excel');
    if (range == null) return;

    final String savedTo = await _controller.exportExcel(range);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Excel exported: $savedTo')));
  }

  void _openProfitAndLoss() {
    Navigator.pushNamed(context, '/tax');
  }

  Future<_ExportRange?> _chooseExportRange(String actionLabel) async {
    final _ExportPeriod? period = await showModalBottomSheet<_ExportPeriod>(
      context: context,
      backgroundColor: _TransactionTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) {
        return _ExportRangeBottomSheet(actionLabel: actionLabel);
      },
    );

    if (!mounted || period == null) return null;

    return switch (period) {
      _ExportPeriod.week => _chooseWeekExportRange(),
      _ExportPeriod.month => _chooseMonthExportRange(),
      _ExportPeriod.year => _chooseYearExportRange(),
    };
  }

  Future<_ExportRange?> _chooseWeekExportRange() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _controller.initialExportDate(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Choose week in calendar',
    );
    if (!mounted || picked == null) return null;

    return _TransactionDateUtils.weekRange(picked);
  }

  Future<_ExportRange?> _chooseMonthExportRange() async {
    final DateTime initial = _controller.initialExportDate();
    final _MonthYear? selected = await _showMonthYearDialog(
      initialMonth: initial.month,
      initialYear: initial.year,
    );
    if (!mounted || selected == null) return null;

    return _TransactionDateUtils.monthRange(
      year: selected.year,
      month: selected.month,
    );
  }

  Future<_ExportRange?> _chooseYearExportRange() async {
    final int? selectedYear = await _showYearDialog(
      initialYear: _controller.initialExportDate().year,
    );
    if (!mounted || selectedYear == null) return null;

    return _TransactionDateUtils.yearRange(selectedYear);
  }

  Future<_MonthYear?> _showMonthYearDialog({
    required int initialMonth,
    required int initialYear,
  }) {
    int selectedMonth = initialMonth;
    int selectedYear = initialYear;

    return showDialog<_MonthYear>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Choose month'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonth,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Month'),
                    items: List<DropdownMenuItem<int>>.generate(12, (
                      int index,
                    ) {
                      final int month = index + 1;
                      return DropdownMenuItem<int>(
                        value: month,
                        child: Text(_shortMonthNames[month]),
                      );
                    }),
                    onChanged: (int? value) {
                      if (value == null) return;
                      setDialogState(() => selectedMonth = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: _TransactionDateUtils.exportYears
                        .map<DropdownMenuItem<int>>(
                          (int year) => DropdownMenuItem<int>(
                            value: year,
                            child: Text('$year'),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (int? value) {
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
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _MonthYear(month: selectedMonth, year: selectedYear),
                    );
                  },
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
    int selectedYear = initialYear;

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Choose year'),
              content: DropdownButtonFormField<int>(
                initialValue: selectedYear,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Year'),
                items: _TransactionDateUtils.exportYears
                    .map<DropdownMenuItem<int>>(
                      (int year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text('$year'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (int? value) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TransactionTokens.screenBackground,
      appBar: AppBar(
        backgroundColor: _TransactionTokens.surface,
        elevation: 0,
        title: const Text('Transaction', style: _TransactionTokens.appBarTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bar_chart,
              color: _TransactionTokens.primaryBlue,
            ),
            onPressed: _controller.loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? child) {
          final _TransactionViewState state = _controller.state;

          return RefreshIndicator(
            onRefresh: _controller.loadTransactions,
            child: state.isLoading
                ? const _LoadingTransactionsList()
                : _TransactionList(
                    state: state,
                    onKindChanged: _controller.setKind,
                    onFilterChanged: _controller.setFilter,
                    onCategoryTap: _chooseCategory,
                    onCategorySelected: _controller.selectExpenseCategory,
                    onExpenseDateRangeChanged: _controller.setExpenseDateRange,
                    onYearChanged: _controller.changeYear,
                    onToggleGroup: _controller.toggleGroup,
                    onDelete: _confirmDeleteItem,
                    onEstimatedTaxTap: _openProfitAndLoss,
                    onExportPdf: _exportPdf,
                    onPrintPdf: _printPdf,
                    onExportExcel: _exportExcel,
                  ),
          );
        },
      ),
    );
  }
}
