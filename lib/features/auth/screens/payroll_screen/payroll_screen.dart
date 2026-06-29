import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:savetep/services/money_formatter.dart';

import 'payroll_controller.dart';
import 'payroll_models.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  static const List<int> _processDayOptions = <int>[1, 2, 3, 5, 7, 10, 14];

  late final PayrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PayrollController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickPayDate() async {
    final PayrollRecord payroll = _controller.state.payroll;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: payroll.payDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Choose pay date',
    );
    if (picked == null || !mounted) return;

    _controller.setPayDate(picked);
  }

  Future<void> _chooseProcessDays() async {
    final PayrollRecord payroll = _controller.state.payroll;
    final int? selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _PayrollTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Process Payroll',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              for (final int days in _processDayOptions)
                ListTile(
                  leading: Icon(
                    days == payroll.processDaysBefore
                        ? Icons.check_circle
                        : Icons.calendar_month_outlined,
                    color: days == payroll.processDaysBefore
                        ? _PayrollTokens.success
                        : _PayrollTokens.textMuted,
                  ),
                  title: Text('$days days before pay date'),
                  subtitle: Text(
                    _formatDate(payroll.payDate.subtract(Duration(days: days))),
                  ),
                  onTap: () => Navigator.pop(context, days),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || !mounted) return;

    _controller.setProcessDaysBefore(selected);
  }

  Future<void> _savePayroll() async {
    try {
      await _controller.save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payroll saved to expenses and reminders.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payroll save failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PayrollTokens.screenBackground,
      appBar: AppBar(
        backgroundColor: _PayrollTokens.surface,
        elevation: 0,
        title: const Text('Payroll', style: _PayrollTokens.appBarTitle),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: _PayrollTokens.textStrong),
            onPressed: _controller.load,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? child) {
          final PayrollViewState state = _controller.state;
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              padding: _PayrollTokens.pagePadding,
              children: <Widget>[
                _PayrollSetupCard(
                  state: state,
                  onPickPayDate: _pickPayDate,
                  onChooseProcessDays: _chooseProcessDays,
                  onScheduleChanged: _controller.setSchedule,
                ),
                const SizedBox(height: 18),
                _EmployeePayrollCard(
                  state: state,
                  onAddEmployee: _controller.addEmployee,
                  onRemoveEmployee: _controller.removeEmployee,
                  onEmployeeChanged: _controller.updateEmployee,
                ),
                const SizedBox(height: 16),
                _SavePayrollButton(
                  isSaving: state.isSaving,
                  onPressed: state.isSaving ? null : _savePayroll,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PayrollSetupCard extends StatelessWidget {
  final PayrollViewState state;
  final VoidCallback onPickPayDate;
  final VoidCallback onChooseProcessDays;
  final ValueChanged<PayrollSchedule> onScheduleChanged;

  const _PayrollSetupCard({
    required this.state,
    required this.onPickPayDate,
    required this.onChooseProcessDays,
    required this.onScheduleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final PayrollRecord payroll = state.payroll;

    return Container(
      decoration: _PayrollTokens.panelDecoration,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _SummaryMetric(
                  label: 'BALANCE',
                  value: formatMoney(state.balance),
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 80, color: _PayrollTokens.divider),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _ProcessDateField(
                  processDate: payroll.processDate,
                  onTap: onChooseProcessDays,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _PayrollTokens.divider),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _DateInputTile(
                  label: 'PAY DATE',
                  value: _formatDate(payroll.payDate),
                  onTap: onPickPayDate,
                ),
              ),
              const SizedBox(width: 18),
              Container(width: 1, height: 70, color: _PayrollTokens.divider),
              const SizedBox(width: 18),
              Expanded(
                child: _ScheduleDropdown(
                  value: payroll.schedule,
                  onChanged: onScheduleChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: _PayrollTokens.divider),
          const SizedBox(height: 18),
          _ReadOnlyField(
            label: 'PAY PERIOD',
            value:
                '${_formatDate(payroll.payPeriodStart)} - ${_formatDate(payroll.payPeriodEnd)}',
            trailing: const Icon(
              Icons.keyboard_arrow_down,
              color: _PayrollTokens.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              const Icon(
                Icons.notifications_active_outlined,
                color: _PayrollTokens.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payroll.processInstruction,
                  style: _PayrollTokens.helperText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MoneySyncStrip(
            totalPay: payroll.totalPay,
            totalDeposits: state.totalDeposits,
            totalExpenses: state.totalExpenses,
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(label, style: _PayrollTokens.fieldLabel),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: _PayrollTokens.balanceValue),
          ),
        ],
      ),
    );
  }
}

class _ProcessDateField extends StatelessWidget {
  final DateTime processDate;
  final VoidCallback onTap;

  const _ProcessDateField({required this.processDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('PROCESS PAYROLL DATE', style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: _TappableField(
                value: _formatDate(processDate),
                icon: Icons.calendar_month_outlined,
                onTap: onTap,
              ),
            ),
            const SizedBox(width: 14),
            IconButton(
              tooltip: 'Choose process days',
              onPressed: onTap,
              icon: const Icon(
                Icons.settings_outlined,
                color: _PayrollTokens.textMuted,
                size: 34,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateInputTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateInputTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        _TappableField(
          value: value,
          icon: Icons.calendar_month_outlined,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _ScheduleDropdown extends StatelessWidget {
  final PayrollSchedule value;
  final ValueChanged<PayrollSchedule> onChanged;

  const _ScheduleDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('PAYROLL SCHEDULE', style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        DropdownButtonFormField<PayrollSchedule>(
          initialValue: value,
          icon: const Icon(Icons.keyboard_arrow_down),
          isExpanded: true,
          decoration: _PayrollTokens.inputDecoration,
          items: PayrollSchedule.values
              .map(
                (PayrollSchedule schedule) => DropdownMenuItem<PayrollSchedule>(
                  value: schedule,
                  child: Text(schedule.label),
                ),
              )
              .toList(growable: false),
          onChanged: (PayrollSchedule? schedule) {
            if (schedule == null) return;
            onChanged(schedule);
          },
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _PayrollTokens.inputBoxDecoration,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _PayrollTokens.inputText,
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }
}

class _TappableField extends StatelessWidget {
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _TappableField({
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _PayrollTokens.inputBoxDecoration,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _PayrollTokens.inputText,
                ),
              ),
              Icon(icon, color: _PayrollTokens.textMuted, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneySyncStrip extends StatelessWidget {
  final double totalPay;
  final double totalDeposits;
  final double totalExpenses;

  const _MoneySyncStrip({
    required this.totalPay,
    required this.totalDeposits,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _PayrollTokens.syncBackground,
        borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
        border: Border.all(color: _PayrollTokens.border),
      ),
      child: Row(
        children: <Widget>[
          _InlineMoneyMetric(label: 'Total Pay', value: totalPay),
          const SizedBox(width: 14),
          _InlineMoneyMetric(label: 'Total Deposit', value: totalDeposits),
          const SizedBox(width: 14),
          _InlineMoneyMetric(label: 'Total Expense', value: totalExpenses),
        ],
      ),
    );
  }
}

class _InlineMoneyMetric extends StatelessWidget {
  final String label;
  final double value;

  const _InlineMoneyMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: _PayrollTokens.inlineLabel),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatMoney(value), style: _PayrollTokens.inlineValue),
          ),
        ],
      ),
    );
  }
}

class _EmployeePayrollCard extends StatelessWidget {
  final PayrollViewState state;
  final VoidCallback onAddEmployee;
  final ValueChanged<String> onRemoveEmployee;
  final void Function(
    String id, {
    String? name,
    double? rate,
    double? regularHours,
    double? overtimeHours,
    double? commission,
    double? tips,
  })
  onEmployeeChanged;

  const _EmployeePayrollCard({
    required this.state,
    required this.onAddEmployee,
    required this.onRemoveEmployee,
    required this.onEmployeeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<PayrollEmployee> employees = state.payroll.employees;

    return Container(
      decoration: _PayrollTokens.panelDecoration,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 790,
              child: Column(
                children: <Widget>[
                  const _EmployeeHeaderRow(),
                  const Divider(height: 1, color: _PayrollTokens.divider),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: employees.length,
                    itemBuilder: (BuildContext context, int index) {
                      final PayrollEmployee employee = employees[index];
                      return _PayrollEmployeeRow(
                        key: ValueKey<String>('payroll-row-${employee.id}'),
                        index: index,
                        employee: employee,
                        canRemove: employees.length > 1,
                        onRemove: () => onRemoveEmployee(employee.id),
                        onChanged:
                            ({
                              String? name,
                              double? rate,
                              double? regularHours,
                              double? overtimeHours,
                              double? commission,
                              double? tips,
                            }) {
                              onEmployeeChanged(
                                employee.id,
                                name: name,
                                rate: rate,
                                regularHours: regularHours,
                                overtimeHours: overtimeHours,
                                commission: commission,
                                tips: tips,
                              );
                            },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              TextButton.icon(
                onPressed: onAddEmployee,
                icon: const Icon(Icons.add),
                label: const Text('Add employee'),
              ),
              const Spacer(),
              Text('Payroll total', style: _PayrollTokens.inlineLabel),
              const SizedBox(width: 10),
              Text(
                formatMoney(state.payroll.totalPay),
                style: _PayrollTokens.footerTotal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmployeeHeaderRow extends StatelessWidget {
  const _EmployeeHeaderRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 48,
      child: Row(
        children: <Widget>[
          SizedBox(width: 44, child: _HeaderCheckBox()),
          _HeaderCell(width: 128, label: 'EMPLOYEE'),
          _HeaderCell(width: 96, label: 'RATE'),
          _HeaderCell(width: 104, label: 'REG PAY HRS'),
          _HeaderCell(width: 94, label: 'OT HRS'),
          _HeaderCell(width: 92, label: 'COMM'),
          _HeaderCell(width: 92, label: 'TIPS'),
          _HeaderCell(width: 104, label: 'TOTAL PAY', alignEnd: true),
          SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _HeaderCheckBox extends StatelessWidget {
  const _HeaderCheckBox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _PayrollTokens.border),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final double width;
  final String label;
  final bool alignEnd;

  const _HeaderCell({
    required this.width,
    required this.label,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(label, style: _PayrollTokens.tableHeader),
      ),
    );
  }
}

class _PayrollEmployeeRow extends StatefulWidget {
  final int index;
  final PayrollEmployee employee;
  final bool canRemove;
  final VoidCallback onRemove;
  final void Function({
    String? name,
    double? rate,
    double? regularHours,
    double? overtimeHours,
    double? commission,
    double? tips,
  })
  onChanged;

  const _PayrollEmployeeRow({
    super.key,
    required this.index,
    required this.employee,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_PayrollEmployeeRow> createState() => _PayrollEmployeeRowState();
}

class _PayrollEmployeeRowState extends State<_PayrollEmployeeRow> {
  late final TextEditingController _nameController;
  late final TextEditingController _rateController;
  late final TextEditingController _regularHoursController;
  late final TextEditingController _overtimeHoursController;
  late final TextEditingController _commissionController;
  late final TextEditingController _tipsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _rateController = TextEditingController(
      text: _amountText(widget.employee.rate),
    );
    _regularHoursController = TextEditingController(
      text: _amountText(widget.employee.regularHours),
    );
    _overtimeHoursController = TextEditingController(
      text: _amountText(widget.employee.overtimeHours),
    );
    _commissionController = TextEditingController(
      text: _amountText(widget.employee.commission),
    );
    _tipsController = TextEditingController(
      text: _amountText(widget.employee.tips),
    );
  }

  @override
  void didUpdateWidget(covariant _PayrollEmployeeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employee.id == widget.employee.id) return;

    _nameController.text = widget.employee.name;
    _rateController.text = _amountText(widget.employee.rate);
    _regularHoursController.text = _amountText(widget.employee.regularHours);
    _overtimeHoursController.text = _amountText(widget.employee.overtimeHours);
    _commissionController.text = _amountText(widget.employee.commission);
    _tipsController.text = _amountText(widget.employee.tips);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _regularHoursController.dispose();
    _overtimeHoursController.dispose();
    _commissionController.dispose();
    _tipsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _PayrollTokens.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 44,
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _PayrollTokens.border),
                ),
                child: const Icon(
                  Icons.check,
                  color: _PayrollTokens.success,
                  size: 24,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 128,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  key: ValueKey<String>(
                    'payroll.employee.${widget.index}.name',
                  ),
                  controller: _nameController,
                  minLines: 1,
                  maxLines: 2,
                  style: _PayrollTokens.employeeName,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (String value) => widget.onChanged(name: value),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.badge_outlined,
                  color: _PayrollTokens.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
          _MoneyInputCell(
            index: widget.index,
            field: 'rate',
            width: 96,
            controller: _rateController,
            onChanged: (double value) => widget.onChanged(rate: value),
          ),
          _MoneyInputCell(
            index: widget.index,
            field: 'regularHours',
            width: 104,
            controller: _regularHoursController,
            hintText: 'Enter',
            onChanged: (double value) => widget.onChanged(regularHours: value),
          ),
          _MoneyInputCell(
            index: widget.index,
            field: 'overtimeHours',
            width: 94,
            controller: _overtimeHoursController,
            hintText: 'Enter',
            onChanged: (double value) => widget.onChanged(overtimeHours: value),
          ),
          _MoneyInputCell(
            index: widget.index,
            field: 'commission',
            width: 92,
            controller: _commissionController,
            hintText: 'Enter',
            onChanged: (double value) => widget.onChanged(commission: value),
          ),
          _MoneyInputCell(
            index: widget.index,
            field: 'tips',
            width: 92,
            controller: _tipsController,
            hintText: 'Enter',
            onChanged: (double value) => widget.onChanged(tips: value),
          ),
          SizedBox(
            width: 104,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatMoney(widget.employee.totalPay),
                style: _PayrollTokens.rowTotal,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: IconButton(
              tooltip: 'Remove employee',
              onPressed: widget.canRemove ? widget.onRemove : null,
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyInputCell extends StatelessWidget {
  final int index;
  final String field;
  final double width;
  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<double> onChanged;

  const _MoneyInputCell({
    required this.index,
    required this.field,
    required this.width,
    required this.controller,
    required this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          height: 72,
          child: TextField(
            key: ValueKey<String>('payroll.employee.$index.$field'),
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textAlign: TextAlign.center,
            style: _PayrollTokens.inputText,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: _PayrollTokens.inputHint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              enabledBorder: _PayrollTokens.cellBorder,
              focusedBorder: _PayrollTokens.focusedCellBorder,
              border: _PayrollTokens.cellBorder,
            ),
            onChanged: (String value) => onChanged(parseMoney(value)),
          ),
        ),
      ),
    );
  }
}

class _SavePayrollButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;

  const _SavePayrollButton({required this.isSaving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: isSaving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_outlined),
        label: Text(isSaving ? 'Saving payroll' : 'Save payroll'),
        style: FilledButton.styleFrom(
          backgroundColor: _PayrollTokens.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_PayrollTokens.cardRadius),
          ),
        ),
      ),
    );
  }
}

String _amountText(double value) {
  if (value == 0) return '';
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
}

String _formatDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}

class _PayrollTokens {
  const _PayrollTokens._();

  static const Color screenBackground = Color(0xFFF5F6F7);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF0F766E);
  static const Color syncBackground = Color(0xFFF8FAFC);
  static const Color textStrong = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFD8DEE8);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF57B82F);

  static const double cardRadius = 8;
  static const double controlRadius = 6;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 16, 16, 24);

  static const List<BoxShadow> panelShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static BoxDecoration get panelDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(cardRadius),
    boxShadow: panelShadow,
  );

  static BoxDecoration get inputBoxDecoration => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(controlRadius),
    border: Border.all(color: border),
  );

  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: primary, width: 1.4),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: border),
    ),
  );

  static OutlineInputBorder get cellBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(controlRadius),
    borderSide: const BorderSide(color: border),
  );

  static OutlineInputBorder get focusedCellBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(controlRadius),
    borderSide: const BorderSide(color: primary, width: 1.5),
  );

  static const TextStyle appBarTitle = TextStyle(
    color: Colors.black87,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle fieldLabel = TextStyle(
    color: Color(0xFF4B5563),
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle balanceValue = TextStyle(
    color: Colors.black,
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle inputText = TextStyle(
    color: textStrong,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle inputHint = TextStyle(
    color: Color(0xFF9CA3AF),
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle helperText = TextStyle(
    color: textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle inlineLabel = TextStyle(
    color: textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle inlineValue = TextStyle(
    color: textStrong,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle tableHeader = TextStyle(
    color: Colors.black,
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle employeeName = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const TextStyle rowTotal = TextStyle(
    color: Colors.black,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle footerTotal = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );
}
