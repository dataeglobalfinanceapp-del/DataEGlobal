part of '../payroll_screen.dart';

class _EmployeePayrollList extends StatelessWidget {
  final PayrollViewState state;
  final VoidCallback onAddEmployee;
  final ValueChanged<String> onRemoveEmployee;
  final _EmployeeChanged onEmployeeChanged;

  const _EmployeePayrollList({
    required this.state,
    required this.onAddEmployee,
    required this.onRemoveEmployee,
    required this.onEmployeeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<PayrollEmployee> employees = state.payroll.employees;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text('Employees', style: _PayrollTokens.sectionTitle),
            ),
            TextButton.icon(
              onPressed: onAddEmployee,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int index = 0; index < employees.length; index += 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PayrollEmployeeCard(
              key: ValueKey<String>(
                'payroll.employee.card.${employees[index].id}',
              ),
              index: index,
              employee: employees[index],
              canRemove: employees.length > 1,
              onRemove: () => onRemoveEmployee(employees[index].id),
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
                      employees[index].id,
                      name: name,
                      rate: rate,
                      regularHours: regularHours,
                      overtimeHours: overtimeHours,
                      commission: commission,
                      tips: tips,
                    );
                  },
            ),
          ),
        _PayrollTotalFooter(totalPay: state.payroll.totalPay),
      ],
    );
  }
}

class _PayrollEmployeeCard extends StatefulWidget {
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

  const _PayrollEmployeeCard({
    super.key,
    required this.index,
    required this.employee,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_PayrollEmployeeCard> createState() => _PayrollEmployeeCardState();
}

class _PayrollEmployeeCardState extends State<_PayrollEmployeeCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _rateController;
  late final TextEditingController _regularHoursController;
  late final TextEditingController _overtimeHoursController;
  late final TextEditingController _commissionController;
  late final TextEditingController _tipsController;
  late bool _isLocked;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _rateController = TextEditingController();
    _regularHoursController = TextEditingController();
    _overtimeHoursController = TextEditingController();
    _commissionController = TextEditingController();
    _tipsController = TextEditingController();
    _syncControllersFromEmployee(widget.employee);
    _isLocked = _hasConfirmedPay(widget.employee);
  }

  @override
  void didUpdateWidget(covariant _PayrollEmployeeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employee.id != widget.employee.id) {
      _syncControllersFromEmployee(widget.employee);
      _isLocked = _hasConfirmedPay(widget.employee);
      return;
    }

    if (_isLocked &&
        _payrollValuesChanged(oldWidget.employee, widget.employee)) {
      _syncControllersFromEmployee(widget.employee);
    }
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

  void _syncControllersFromEmployee(PayrollEmployee employee) {
    _nameController.text = employee.name;
    _rateController.text = _amountText(employee.rate);
    _regularHoursController.text = _amountText(employee.regularHours);
    _overtimeHoursController.text = _amountText(employee.overtimeHours);
    _commissionController.text = _amountText(employee.commission);
    _tipsController.text = _amountText(employee.tips);
  }

  bool _hasConfirmedPay(PayrollEmployee employee) => employee.totalPay > 0;

  bool _payrollValuesChanged(PayrollEmployee previous, PayrollEmployee next) {
    return previous.name != next.name ||
        previous.rate != next.rate ||
        previous.regularHours != next.regularHours ||
        previous.overtimeHours != next.overtimeHours ||
        previous.commission != next.commission ||
        previous.tips != next.tips;
  }

  void _edit() {
    setState(() => _isLocked = false);
  }

  void _confirm() {
    final String name = _nameController.text.trim();
    widget.onChanged(
      name: name.isEmpty ? widget.employee.name : name,
      rate: parseMoney(_rateController.text),
      regularHours: parseMoney(_regularHoursController.text),
      overtimeHours: parseMoney(_overtimeHoursController.text),
      commission: parseMoney(_commissionController.text),
      tips: parseMoney(_tipsController.text),
    );
    FocusScope.of(context).unfocus();
    setState(() => _isLocked = true);
  }

  @override
  Widget build(BuildContext context) {
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
                child: TextField(
                  key: ValueKey<String>(
                    'payroll.employee.${widget.index}.name',
                  ),
                  controller: _nameController,
                  readOnly: _isLocked,
                  minLines: 1,
                  maxLines: 2,
                  style: _PayrollTokens.employeeName,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  const Text('TOTAL PAY', style: _PayrollTokens.cardMiniLabel),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(widget.employee.totalPay),
                    style: _PayrollTokens.rowTotal,
                  ),
                ],
              ),
              if (widget.canRemove)
                SizedBox(
                  width: 36,
                  child: IconButton(
                    tooltip: 'Remove employee',
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _EmployeeInputGrid(
            fields: <Widget>[
              _PayrollAmountField(
                index: widget.index,
                field: 'rate',
                label: 'RATE',
                controller: _rateController,
                readOnly: _isLocked,
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'regularHours',
                label: 'REG HRS',
                controller: _regularHoursController,
                hintText: 'Enter',
                readOnly: _isLocked,
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'overtimeHours',
                label: 'OT HRS',
                controller: _overtimeHoursController,
                hintText: 'Enter',
                readOnly: _isLocked,
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'commission',
                label: 'COMM',
                controller: _commissionController,
                hintText: 'Enter',
                readOnly: _isLocked,
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'tips',
                label: 'TIPS',
                controller: _tipsController,
                hintText: 'Enter',
                readOnly: _isLocked,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PayrollEmployeeActions(
            index: widget.index,
            onEdit: _edit,
            onConfirm: _confirm,
          ),
        ],
      ),
    );
  }
}

class _EmployeeInputGrid extends StatelessWidget {
  final List<Widget> fields;

  const _EmployeeInputGrid({required this.fields});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final int columns = switch (maxWidth) {
          >= 300 => 2,
          _ => 1,
        };
        const double gap = 16;
        final double width = columns == 1
            ? maxWidth
            : (maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 12,
          children: <Widget>[
            for (final Widget field in fields)
              SizedBox(width: width, child: field),
          ],
        );
      },
    );
  }
}

class _PayrollEmployeeActions extends StatelessWidget {
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;

  const _PayrollEmployeeActions({
    required this.index,
    required this.onEdit,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 330;
        final Widget editButton = OutlinedButton(
          key: ValueKey<String>('payroll.employee.$index.edit'),
          onPressed: onEdit,
          style: OutlinedButton.styleFrom(
            foregroundColor: _PayrollTokens.tabSelected,
            side: const BorderSide(color: _PayrollTokens.tabSelected),
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
            ),
          ),
          child: const Text('Edit'),
        );
        final Widget confirmButton = FilledButton(
          key: ValueKey<String>('payroll.employee.$index.confirm'),
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: _PayrollTokens.tabSelected,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
            ),
          ),
          child: const Text('Confirm'),
        );

        if (narrow) {
          return Row(
            children: <Widget>[
              Expanded(child: editButton),
              const SizedBox(width: 12),
              Expanded(child: confirmButton),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            SizedBox(width: 112, child: editButton),
            const SizedBox(width: 12),
            SizedBox(width: 128, child: confirmButton),
          ],
        );
      },
    );
  }
}

class _PayrollAmountField extends StatelessWidget {
  final int index;
  final String field;
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool readOnly;

  const _PayrollAmountField({
    required this.index,
    required this.field,
    required this.label,
    required this.controller,
    required this.readOnly,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _PayrollTokens.cardFieldLabel),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: TextField(
            key: ValueKey<String>('payroll.employee.$index.$field'),
            controller: controller,
            readOnly: readOnly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textAlign: TextAlign.start,
            style: _PayrollTokens.inputText,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: _PayrollTokens.inputHint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              fillColor: readOnly
                  ? _PayrollTokens.lockedFieldBackground
                  : _PayrollTokens.surface,
              filled: true,
              enabledBorder: _PayrollTokens.cellBorder,
              focusedBorder: _PayrollTokens.focusedCellBorder,
              border: _PayrollTokens.cellBorder,
            ),
          ),
        ),
      ],
    );
  }
}

class _PayrollTotalFooter extends StatelessWidget {
  final double totalPay;

  const _PayrollTotalFooter({required this.totalPay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _PayrollTokens.surface,
        borderRadius: BorderRadius.circular(_PayrollTokens.cardRadius),
        border: Border.all(color: _PayrollTokens.divider),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text('Payroll total', style: _PayrollTokens.inlineLabel),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatMoney(totalPay),
              style: _PayrollTokens.footerTotal,
            ),
          ),
        ],
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
