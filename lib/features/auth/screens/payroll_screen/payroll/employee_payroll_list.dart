part of '../payroll_screen.dart';

class _EmployeePayrollList extends StatefulWidget {
  final PayrollViewState state;
  final VoidCallback onAddEmployee;
  final _EmployeeChanged onEmployeeChanged;

  const _EmployeePayrollList({
    required this.state,
    required this.onAddEmployee,
    required this.onEmployeeChanged,
  });

  @override
  State<_EmployeePayrollList> createState() => _EmployeePayrollListState();
}

class _EmployeePayrollListState extends State<_EmployeePayrollList> {
  final Map<String, GlobalKey> _cardKeys = <String, GlobalKey>{};
  String? _focusedUnconfirmedEmployeeId;

  @override
  void didUpdateWidget(covariant _EmployeePayrollList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool focusedEmployeeStillNeedsConfirmation = widget
        .state
        .payroll
        .employees
        .any(
          (PayrollEmployee employee) =>
              employee.id == _focusedUnconfirmedEmployeeId &&
              !employee.isPayrollConfirmed,
        );
    if (!focusedEmployeeStillNeedsConfirmation) {
      _focusedUnconfirmedEmployeeId = null;
    }
  }

  Future<void> _handleEmployeeChanged(
    PayrollEmployee employee, {
    String? name,
    double? rate,
    double? regularHours,
    double? overtimeHours,
    double? commission,
    double? tips,
    PayrollAction? payrollAction,
    bool? confirmPayroll,
  }) async {
    await widget.onEmployeeChanged(
      employee.id,
      name: name,
      rate: rate,
      regularHours: regularHours,
      overtimeHours: overtimeHours,
      commission: commission,
      tips: tips,
      payrollAction: payrollAction,
      confirmPayroll: confirmPayroll,
    );
    if (!mounted || confirmPayroll != true) return;

    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _focusFirstUnconfirmedEmployee();
    });
  }

  void _focusFirstUnconfirmedEmployee() {
    final PayrollEmployee? employee = _firstUnconfirmedEmployee();
    if (employee == null) {
      if (_focusedUnconfirmedEmployeeId != null) {
        setState(() => _focusedUnconfirmedEmployeeId = null);
      }
      return;
    }

    setState(() => _focusedUnconfirmedEmployeeId = employee.id);
    final BuildContext? cardContext = _cardKeys[employee.id]?.currentContext;
    if (cardContext == null) return;

    Scrollable.ensureVisible(
      cardContext,
      alignment: 0.08,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  PayrollEmployee? _firstUnconfirmedEmployee() {
    for (final PayrollEmployee employee in widget.state.payroll.employees) {
      if (!employee.isPayrollConfirmed) return employee;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<PayrollEmployee> employees = widget.state.payroll.employees;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text('Employees', style: _PayrollTokens.sectionTitle),
            ),
            TextButton.icon(
              onPressed: widget.onAddEmployee,
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
              cardKey: _cardKeys.putIfAbsent(
                employees[index].id,
                () => GlobalKey(),
              ),
              index: index,
              employee: employees[index],
              showConfirmationWarning:
                  _focusedUnconfirmedEmployeeId == employees[index].id &&
                  !employees[index].isPayrollConfirmed,
              onChanged:
                  ({
                    String? name,
                    double? rate,
                    double? regularHours,
                    double? overtimeHours,
                    double? commission,
                    double? tips,
                    PayrollAction? payrollAction,
                    bool? confirmPayroll,
                  }) {
                    return _handleEmployeeChanged(
                      employees[index],
                      name: name,
                      rate: rate,
                      regularHours: regularHours,
                      overtimeHours: overtimeHours,
                      commission: commission,
                      tips: tips,
                      payrollAction: payrollAction,
                      confirmPayroll: confirmPayroll,
                    );
                  },
            ),
          ),
        _PayrollTotalFooter(totalPay: widget.state.payroll.totalPay),
      ],
    );
  }
}

class _PayrollEmployeeCard extends StatefulWidget {
  final GlobalKey cardKey;
  final int index;
  final PayrollEmployee employee;
  final bool showConfirmationWarning;
  final Future<void> Function({
    String? name,
    double? rate,
    double? regularHours,
    double? overtimeHours,
    double? commission,
    double? tips,
    PayrollAction? payrollAction,
    bool? confirmPayroll,
  })
  onChanged;

  const _PayrollEmployeeCard({
    super.key,
    required this.cardKey,
    required this.index,
    required this.employee,
    required this.showConfirmationWarning,
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
  PayrollAction _selectedAction = PayrollAction.same;
  bool _isSyncingControllers = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _rateController = TextEditingController();
    _regularHoursController = TextEditingController();
    _overtimeHoursController = TextEditingController();
    _commissionController = TextEditingController();
    _tipsController = TextEditingController();
    _selectedAction = widget.employee.payrollAction;
    _syncControllersFromEmployee(widget.employee);
    _rateController.addListener(_handlePayrollFieldEdited);
    _regularHoursController.addListener(_handlePayrollFieldEdited);
    _overtimeHoursController.addListener(_handlePayrollFieldEdited);
    _commissionController.addListener(_handlePayrollFieldEdited);
    _tipsController.addListener(_handlePayrollFieldEdited);
  }

  @override
  void didUpdateWidget(covariant _PayrollEmployeeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employee.id != widget.employee.id) {
      _syncControllersFromEmployee(widget.employee);
      return;
    }

    if (_payrollValuesChanged(oldWidget.employee, widget.employee)) {
      _syncControllersFromEmployee(widget.employee);
    }
    if (oldWidget.employee.payrollAction != widget.employee.payrollAction) {
      _selectedAction = widget.employee.payrollAction;
    }
  }

  @override
  void dispose() {
    _rateController.removeListener(_handlePayrollFieldEdited);
    _regularHoursController.removeListener(_handlePayrollFieldEdited);
    _overtimeHoursController.removeListener(_handlePayrollFieldEdited);
    _commissionController.removeListener(_handlePayrollFieldEdited);
    _tipsController.removeListener(_handlePayrollFieldEdited);
    _nameController.dispose();
    _rateController.dispose();
    _regularHoursController.dispose();
    _overtimeHoursController.dispose();
    _commissionController.dispose();
    _tipsController.dispose();
    super.dispose();
  }

  void _syncControllersFromEmployee(PayrollEmployee employee) {
    _isSyncingControllers = true;
    _nameController.text = employee.name;
    _rateController.text = _amountText(employee.rate);
    _regularHoursController.text = _amountText(employee.regularHours);
    _overtimeHoursController.text = _amountText(employee.overtimeHours);
    _commissionController.text = _amountText(employee.commission);
    _tipsController.text = _amountText(employee.tips);
    _selectedAction = employee.payrollAction;
    _isSyncingControllers = false;
  }

  void _syncPayrollFieldsToZero() {
    _isSyncingControllers = true;
    _rateController.clear();
    _regularHoursController.clear();
    _overtimeHoursController.clear();
    _commissionController.clear();
    _tipsController.clear();
    _isSyncingControllers = false;
  }

  void _handlePayrollFieldEdited() {
    if (_isSyncingControllers || _selectedAction == PayrollAction.change) {
      return;
    }
    setState(() => _selectedAction = PayrollAction.change);
  }

  bool _payrollValuesChanged(PayrollEmployee previous, PayrollEmployee next) {
    return previous.name != next.name ||
        previous.rate != next.rate ||
        previous.regularHours != next.regularHours ||
        previous.overtimeHours != next.overtimeHours ||
        previous.commission != next.commission ||
        previous.tips != next.tips ||
        previous.payrollAction != next.payrollAction ||
        previous.isPayrollConfirmed != next.isPayrollConfirmed;
  }

  Future<void> _confirm() async {
    final String name = _nameController.text.trim();
    await widget.onChanged(
      name: name.isEmpty ? widget.employee.name : name,
      rate: parseMoney(_rateController.text),
      regularHours: parseMoney(_regularHoursController.text),
      overtimeHours: parseMoney(_overtimeHoursController.text),
      commission: parseMoney(_commissionController.text),
      tips: parseMoney(_tipsController.text),
      payrollAction: _selectedAction,
      confirmPayroll: true,
    );
    if (!mounted) return;

    FocusScope.of(context).unfocus();
  }

  Future<void> _selectAction(PayrollAction action) async {
    if (_selectedAction == action && !action.clearsPayroll) return;

    setState(() => _selectedAction = action);
    if (action.clearsPayroll) {
      _syncPayrollFieldsToZero();
      await widget.onChanged(
        rate: 0,
        regularHours: 0,
        overtimeHours: 0,
        commission: 0,
        tips: 0,
        payrollAction: action,
      );
      return;
    }

    await widget.onChanged(payrollAction: action);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: widget.cardKey,
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
            ],
          ),
          if (widget.showConfirmationWarning) ...<Widget>[
            const SizedBox(height: 8),
            const Text(
              'Please confirm payroll for this employee.',
              style: _PayrollTokens.errorText,
            ),
          ],
          const SizedBox(height: 14),
          _EmployeeInputGrid(
            fields: <Widget>[
              _PayrollAmountField(
                index: widget.index,
                field: 'rate',
                label: 'RATE',
                controller: _rateController,
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'regularHours',
                label: 'REG HRS',
                controller: _regularHoursController,
                hintText: 'Enter',
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'overtimeHours',
                label: 'OT HRS',
                controller: _overtimeHoursController,
                hintText: 'Enter',
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'commission',
                label: 'COMM',
                controller: _commissionController,
                hintText: 'Enter',
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'tips',
                label: 'TIPS',
                controller: _tipsController,
                hintText: 'Enter',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PayrollEmployeeActions(
            index: widget.index,
            selectedAction: _selectedAction,
            onActionSelected: _selectAction,
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
  final PayrollAction selectedAction;
  final ValueChanged<PayrollAction> onActionSelected;
  final VoidCallback onConfirm;

  const _PayrollEmployeeActions({
    required this.index,
    required this.selectedAction,
    required this.onActionSelected,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 430;
        final Widget actionBar = _PayrollStatusOptionHolder(
          keyPrefix: 'payroll.employee.$index.action',
          selectedAction: selectedAction,
          onSelected: onActionSelected,
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              actionBar,
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: confirmButton),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(child: actionBar),
            const SizedBox(width: 14),
            SizedBox(width: 128, child: confirmButton),
          ],
        );
      },
    );
  }
}

class _PayrollStatusOptionHolder extends StatelessWidget {
  final String keyPrefix;
  final PayrollAction selectedAction;
  final ValueChanged<PayrollAction> onSelected;

  const _PayrollStatusOptionHolder({
    required this.keyPrefix,
    required this.selectedAction,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _PayrollTokens.surface,
        borderRadius: BorderRadius.circular(_PayrollTokens.cardRadius),
        border: Border.all(color: _PayrollTokens.border),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final PayrollAction action in PayrollAction.values)
            _PayrollActionButton(
              key: ValueKey<String>('$keyPrefix.${action.name}'),
              action: action,
              isSelected: action == selectedAction,
              onTap: () => onSelected(action),
            ),
        ],
      ),
    );
  }
}

class _PayrollActionButton extends StatelessWidget {
  final PayrollAction action;
  final bool isSelected;
  final VoidCallback onTap;

  const _PayrollActionButton({
    super.key,
    required this.action,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground = isSelected
        ? Colors.white
        : _PayrollTokens.textMuted;
    final Color background = isSelected
        ? _PayrollTokens.tabSelected
        : _PayrollTokens.surface;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, minWidth: 74),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Center(
              child: Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PayrollAmountField extends StatelessWidget {
  final int index;
  final String field;
  final String label;
  final TextEditingController controller;
  final String? hintText;

  const _PayrollAmountField({
    required this.index,
    required this.field,
    required this.label,
    required this.controller,
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
              fillColor: _PayrollTokens.surface,
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

String _amountText(double value) {
  if (value == 0) return '';
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
}
