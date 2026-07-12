part of '../payroll_screen.dart';

class _EmployeePayrollList extends StatefulWidget {
  final PayrollViewState state;
  final _EmployeeChanged onEmployeeChanged;

  const _EmployeePayrollList({
    required this.state,
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
        const Text('Employees', style: _PayrollTokens.sectionTitle),
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
              _PayrollActionField(
                index: widget.index,
                selectedAction: _selectedAction,
                onActionSelected: _selectAction,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _PayrollConfirmButton(
              index: widget.index,
              onConfirm: _confirm,
            ),
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

class _PayrollActionField extends StatelessWidget {
  final int index;
  final PayrollAction selectedAction;
  final ValueChanged<PayrollAction> onActionSelected;

  const _PayrollActionField({
    required this.index,
    required this.selectedAction,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 25),
        _PayrollStatusDropdown(
          keyPrefix: 'payroll.employee.$index.action',
          selectedStatus: selectedAction,
          statusOptions: PayrollAction.values,
          onSelected: onActionSelected,
        ),
      ],
    );
  }
}

class _PayrollConfirmButton extends StatelessWidget {
  final int index;
  final VoidCallback onConfirm;

  const _PayrollConfirmButton({required this.index, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: ValueKey<String>('payroll.employee.$index.confirm'),
      onPressed: onConfirm,
      style: FilledButton.styleFrom(
        backgroundColor: _PayrollTokens.tabSelected,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
        ),
      ),
      child: const Text('Confirm'),
    );
  }
}

class _PayrollStatusDropdown extends StatelessWidget {
  final String keyPrefix;
  final PayrollAction selectedStatus;
  final Iterable<PayrollAction> statusOptions;
  final ValueChanged<PayrollAction> onSelected;

  const _PayrollStatusDropdown({
    required this.keyPrefix,
    required this.selectedStatus,
    required this.statusOptions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<PayrollAction> options = statusOptions.toList(growable: false);

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _PayrollTokens.surface,
          borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
          border: Border.all(color: _PayrollTokens.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<PayrollAction>(
            key: ValueKey<String>('$keyPrefix.dropdown'),
            value: selectedStatus,
            isExpanded: true,
            borderRadius: BorderRadius.circular(_PayrollTokens.cardRadius),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: _PayrollTokens.tabSelected,
            ),
            selectedItemBuilder: (BuildContext context) {
              return <Widget>[
                for (final PayrollAction action in options)
                  _PayrollStatusValue(status: action),
              ];
            },
            items: options
                .map(
                  (PayrollAction action) => DropdownMenuItem<PayrollAction>(
                    key: ValueKey<String>('$keyPrefix.${action.name}'),
                    value: action,
                    child: _PayrollStatusMenuItem(
                      status: action,
                      isSelected: action == selectedStatus,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (PayrollAction? action) {
              if (action == null) return;
              onSelected(action);
            },
          ),
        ),
      ),
    );
  }
}

class _PayrollStatusValue extends StatelessWidget {
  final PayrollAction status;

  const _PayrollStatusValue({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _PayrollTokens.tabSelected,
        borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PayrollStatusMenuItem extends StatelessWidget {
  final PayrollAction status;
  final bool isSelected;

  const _PayrollStatusMenuItem({
    required this.status,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isSelected
        ? _PayrollTokens.tabSelected
        : _PayrollTokens.textMuted;

    return Text(
      status.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: textColor,
        fontSize: 13,
        fontWeight: FontWeight.w800,
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
            style: _PayrollTokens.inputText.copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: _PayrollTokens.inputHint.copyWith(fontSize: 15),
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
