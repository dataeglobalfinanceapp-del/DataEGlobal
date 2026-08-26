import 'package:flutter/material.dart';

import 'package:savetep/features/auth/screens/saving_screen/saving_screen_controller.dart';
import 'package:savetep/features/auth/screens/saving_screen/saving_screen_models.dart';
import 'package:savetep/features/auth/screens/saving_screen/saving_screen_widgets.dart';
import 'package:savetep/services/money_formatter.dart';

class SavingScreen extends StatefulWidget {
  const SavingScreen({super.key});

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  late final SavingScreenController _screenController;
  final Map<String, TextEditingController> _savedControllers = {};
  final Map<String, SavingPeriodRow> _controllerRows = {};

  @override
  void initState() {
    super.initState();
    _screenController = SavingScreenController()
      ..addListener(_onStateChanged)
      ..loadData();
  }

  @override
  void dispose() {
    _screenController
      ..removeListener(_onStateChanged)
      ..dispose();
    for (final controller in _savedControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _confirmSavedAmount(SavingPeriodRow row) {
    final controller = _controllerFor(row);
    _screenController.recordSavedAmount(row, parseMoney(controller.text));
    _refreshSavedControllers();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  TextEditingController _controllerFor(SavingPeriodRow row) {
    _controllerRows[row.key] = row;

    final existing = _savedControllers[row.key];
    if (existing != null) return existing;

    final controller = TextEditingController(text: _formattedSavedAmount(row));
    _savedControllers[row.key] = controller;
    return controller;
  }

  void _refreshSavedControllers() {
    for (final entry in _savedControllers.entries) {
      final row = _controllerRows[entry.key];
      if (row == null) continue;

      final displayAmount = _formattedSavedAmount(row);
      if (entry.value.text == displayAmount) continue;

      entry.value.value = TextEditingValue(
        text: displayAmount,
        selection: TextSelection.collapsed(offset: displayAmount.length),
      );
    }
  }

  String _formattedSavedAmount(SavingPeriodRow row) {
    final amount = _screenController.savedAmountFor(row);
    return amount == 0 ? '' : formatMoney(amount, symbol: false);
  }

  Future<void> _editSavingRate() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) =>
          SavingRateDialog(initialRate: _screenController.savingRate),
    );

    if (result == null || !mounted) return;
    _screenController.setSavingRate(result);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _screenController.savingRows;
    final visibleRows = _screenController.visibleRows(rows);
    final pastRows = _screenController.pastRows(rows);

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
          'Saving Plan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _screenController.loadData,
        child: _screenController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    sliver: SliverList.list(
                      children: [
                        SavingSummary(
                          totalDeposit: _screenController.totalDeposit,
                          totalSaving: _screenController.totalSaving,
                          savingRate: _screenController.savingRate,
                          totalSavingTarget:
                              _screenController.totalSavingTarget,
                          periodLabel: _screenController.period.label,
                          periodTarget: _screenController.periodTarget(rows),
                          onEditRate: _editSavingRate,
                        ),
                        const SizedBox(height: 10),
                        SavingPeriodToggle(
                          period: _screenController.period,
                          onChanged: _screenController.setPeriod,
                        ),
                        const SizedBox(height: 12),
                        YearSelector(
                          year: _screenController.year,
                          onPrev: () => _screenController.changeYear(-1),
                          onNext: () => _screenController.changeYear(1),
                        ),
                        const SizedBox(height: 12),
                        if (pastRows.isNotEmpty) ...[
                          PastPeriodsToggle(
                            label: _screenController.period.pastLabel,
                            showAll: _screenController.showPastPeriods,
                            count: pastRows.length,
                            onToggle: _screenController.togglePastPeriods,
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SavingRowsHeader(),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    sliver: SliverList.builder(
                      itemCount: visibleRows.length,
                      itemBuilder: (context, index) {
                        final row = visibleRows[index];
                        return SavingPlanRow(
                          key: ValueKey(row.key),
                          row: row,
                          period: _screenController.period,
                          controller: _controllerFor(row),
                          remainingAmount: _screenController.remainingAmountFor(
                            row,
                          ),
                          onConfirm: () => _confirmSavedAmount(row),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
      ),
    );
  }
}
