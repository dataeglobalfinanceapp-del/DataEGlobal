part of '../payroll_screen.dart';

class _PayrollSettingsScreen extends StatefulWidget {
  final PayrollController controller;

  const _PayrollSettingsScreen({required this.controller});

  @override
  State<_PayrollSettingsScreen> createState() => _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends State<_PayrollSettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _employeeRowKeys = <String, GlobalKey>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openEmployeeSetupEditor(PayrollEmployee employee) async {
    final EmployeePayrollSetup? setup =
        await showModalBottomSheet<EmployeePayrollSetup>(
          context: context,
          isScrollControlled: true,
          backgroundColor: _PayrollTokens.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          builder: (BuildContext context) {
            return _EmployeePayrollSetupEditor(employee: employee);
          },
        );
    if (setup == null || !mounted) return;

    await widget.controller.updateEmployeePayrollSetup(employee.id, setup);
  }

  void _jumpToFirstMissingSetup(List<PayrollEmployee> employees) {
    for (final PayrollEmployee employee in employees) {
      if (employee.payrollSetup != null) continue;

      final BuildContext? rowContext =
          _employeeRowKeys[employee.id]?.currentContext;
      if (rowContext != null) {
        Scrollable.ensureVisible(
          rowContext,
          alignment: 0.12,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PayrollTokens.screenBackground,
      appBar: AppBar(
        backgroundColor: _PayrollTokens.surface,
        elevation: 0,
        title: const Text(
          'Payroll Settings',
          style: _PayrollTokens.appBarTitle,
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (BuildContext context, Widget? child) {
          final PayrollViewState state = widget.controller.state;
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<PayrollEmployee> employees = state.payroll.employees;
          _employeeRowKeys.removeWhere(
            (String id, GlobalKey key) =>
                !employees.any((PayrollEmployee employee) => employee.id == id),
          );

          return SingleChildScrollView(
            controller: _scrollController,
            padding: _PayrollTokens.pagePadding,
            child: _PayrollEmployeeSetupList(
              employees: employees,
              rowKeyForEmployee: (PayrollEmployee employee) =>
                  _employeeRowKeys.putIfAbsent(employee.id, () => GlobalKey()),
              onMissingWarningTap: () => _jumpToFirstMissingSetup(employees),
              onEditEmployee: _openEmployeeSetupEditor,
            ),
          );
        },
      ),
    );
  }
}

class _PayrollEmployeeSetupList extends StatelessWidget {
  final List<PayrollEmployee> employees;
  final GlobalKey Function(PayrollEmployee employee) rowKeyForEmployee;
  final VoidCallback onMissingWarningTap;
  final ValueChanged<PayrollEmployee> onEditEmployee;

  const _PayrollEmployeeSetupList({
    required this.employees,
    required this.rowKeyForEmployee,
    required this.onMissingWarningTap,
    required this.onEditEmployee,
  });

  @override
  Widget build(BuildContext context) {
    final int missingSetupCount = employees
        .where((PayrollEmployee employee) => employee.payrollSetup == null)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (missingSetupCount > 0) ...<Widget>[
          _PayrollSetupWarning(
            missingSetupCount: missingSetupCount,
            onTap: onMissingWarningTap,
          ),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: _PayrollTokens.panelDecoration,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              if (employees.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 24, 18, 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No employees found.',
                      style: _PayrollTokens.helperText,
                    ),
                  ),
                )
              else
                for (int index = 0; index < employees.length; index += 1)
                  _PayrollEmployeeSetupRow(
                    key: rowKeyForEmployee(employees[index]),
                    employee: employees[index],
                    showDivider: index < employees.length - 1,
                    onEdit: () => onEditEmployee(employees[index]),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PayrollSetupWarning extends StatelessWidget {
  final int missingSetupCount;
  final VoidCallback onTap;

  const _PayrollSetupWarning({
    required this.missingSetupCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _PayrollTokens.warningBackground,
      borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.warning_amber_rounded,
                color: _PayrollTokens.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$missingSetupCount employees not have payroll setup.',
                  style: _PayrollTokens.cautionText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayrollEmployeeSetupRow extends StatelessWidget {
  final PayrollEmployee employee;
  final bool showDivider;
  final VoidCallback onEdit;

  const _PayrollEmployeeSetupRow({
    super.key,
    required this.employee,
    required this.showDivider,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final EmployeePayrollSetup? setup = employee.payrollSetup;
    final String scheduleText = setup?.schedule.statusLabel ?? 'None';
    final Color scheduleColor = setup == null
        ? _PayrollTokens.error
        : _PayrollTokens.textMuted;

    return Material(
      color: _PayrollTokens.surface,
      child: InkWell(
        onTap: onEdit,
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: showDivider
                    ? _PayrollTokens.divider
                    : Colors.transparent,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  employee.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _PayrollTokens.employeeListName,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  scheduleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: scheduleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Edit payroll setup',
                onPressed: onEdit,
                icon: const Icon(Icons.settings_outlined),
                color: _PayrollTokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeePayrollSetupEditor extends StatefulWidget {
  final PayrollEmployee employee;

  const _EmployeePayrollSetupEditor({required this.employee});

  @override
  State<_EmployeePayrollSetupEditor> createState() =>
      _EmployeePayrollSetupEditorState();
}

class _EmployeePayrollSetupEditorState
    extends State<_EmployeePayrollSetupEditor> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _paidAfterDaysController;
  late final TextEditingController _remindAfterDaysController;
  late final TextEditingController _rateController;
  EmployeePayrollSchedule? _schedule;
  EmployeePayrollWeekday? _weekday;

  @override
  void initState() {
    super.initState();
    final EmployeePayrollSetup? setup = widget.employee.payrollSetup;
    _schedule = setup?.schedule;
    _weekday = setup?.weekday;
    _paidAfterDaysController = TextEditingController(
      text: (setup?.paidAfterDays ?? 0).toString(),
    );
    _remindAfterDaysController = TextEditingController(
      text: (setup?.remindAfterDays ?? 0).toString(),
    );
    _rateController = TextEditingController(
      text: _amountText(setup?.rate ?? widget.employee.rate),
    );
  }

  @override
  void dispose() {
    _paidAfterDaysController.dispose();
    _remindAfterDaysController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _handleScheduleChanged(EmployeePayrollSchedule? schedule) {
    if (schedule == null) return;

    setState(() {
      _schedule = schedule;
      if (schedule.requiresWeekday) {
        _weekday ??= EmployeePayrollWeekday.monday;
      } else {
        _weekday = null;
      }
    });
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) return;

    final EmployeePayrollSchedule? schedule = _schedule;
    if (schedule == null) return;

    final EmployeePayrollSetup setup = EmployeePayrollSetup(
      schedule: schedule,
      weekday: schedule.requiresWeekday ? _weekday : null,
      paidAfterDays: int.parse(_paidAfterDaysController.text.trim()),
      remindAfterDays: int.parse(_remindAfterDaysController.text.trim()),
      rate: parseMoney(_rateController.text),
    );
    Navigator.pop(context, setup);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.employee.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _PayrollTokens.dialogTitle,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _PayrollSetupDropdownField<EmployeePayrollSchedule>(
                  fieldKey: const ValueKey<String>(
                    'payroll.employeeSetup.schedule',
                  ),
                  label: 'Payroll schedule',
                  value: _schedule,
                  hintText: 'Select payroll schedule',
                  items: EmployeePayrollSchedule.values,
                  itemLabel: (EmployeePayrollSchedule schedule) =>
                      schedule.label,
                  validator: (EmployeePayrollSchedule? schedule) =>
                      schedule == null ? 'Choose a payroll schedule' : null,
                  onChanged: _handleScheduleChanged,
                ),
                if (_schedule?.requiresWeekday == true) ...<Widget>[
                  const SizedBox(height: 16),
                  _PayrollSetupDropdownField<EmployeePayrollWeekday>(
                    fieldKey: const ValueKey<String>(
                      'payroll.employeeSetup.weekday',
                    ),
                    label: 'Weekday',
                    value: _weekday,
                    hintText: 'Select weekday',
                    items: EmployeePayrollWeekday.values,
                    itemLabel: (EmployeePayrollWeekday weekday) =>
                        weekday.label,
                    validator: (EmployeePayrollWeekday? weekday) =>
                        weekday == null ? 'Select weekday' : null,
                    onChanged: (EmployeePayrollWeekday? weekday) =>
                        setState(() => _weekday = weekday),
                  ),
                ],
                const SizedBox(height: 16),
                _PayrollSetupNumberField(
                  fieldKey: const ValueKey<String>(
                    'payroll.employeeSetup.paidAfterDays',
                  ),
                  label: 'Paid after X days after period end',
                  controller: _paidAfterDaysController,
                  validator:
                      EmployeePayrollSetupValidators.validatePaidAfterDays,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _PayrollSetupNumberField(
                  fieldKey: const ValueKey<String>(
                    'payroll.employeeSetup.remindAfterDays',
                  ),
                  label: 'Remind X days after period end',
                  controller: _remindAfterDaysController,
                  validator:
                      EmployeePayrollSetupValidators.validateRemindAfterDays,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                _PayrollSetupRateField(
                  fieldKey: const ValueKey<String>(
                    'payroll.employeeSetup.rate',
                  ),
                  controller: _rateController,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    key: const ValueKey<String>('payroll.employeeSetup.save'),
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _PayrollTokens.tabSelected,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _PayrollTokens.controlRadius,
                        ),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PayrollSetupDropdownField<T> extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final T? value;
  final String hintText;
  final List<T> items;
  final String Function(T item) itemLabel;
  final FormFieldValidator<T> validator;
  final ValueChanged<T?> onChanged;

  const _PayrollSetupDropdownField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.hintText,
    required this.items,
    required this.itemLabel,
    required this.validator,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _PayrollSetupFieldFrame(
      label: label,
      child: DropdownButtonFormField<T>(
        key: fieldKey,
        initialValue: value,
        icon: const Icon(Icons.keyboard_arrow_down),
        isExpanded: true,
        decoration: _PayrollTokens.inputDecoration.copyWith(
          hintText: hintText,
          hintStyle: _PayrollTokens.inputHint,
        ),
        items: items
            .map(
              (T item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              ),
            )
            .toList(growable: false),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }
}

class _PayrollSetupNumberField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;

  const _PayrollSetupNumberField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.validator,
    required this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return _PayrollSetupFieldFrame(
      label: label,
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        textInputAction: textInputAction,
        validator: validator,
        style: _PayrollTokens.inputText,
        decoration: _PayrollTokens.inputDecoration,
      ),
    );
  }
}

class _PayrollSetupRateField extends StatelessWidget {
  final Key fieldKey;
  final TextEditingController controller;

  const _PayrollSetupRateField({
    required this.fieldKey,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return _PayrollSetupFieldFrame(
      label: 'Rate',
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        textInputAction: TextInputAction.done,
        validator: EmployeePayrollSetupValidators.validatePayrollRate,
        style: _PayrollTokens.inputText,
        decoration: _PayrollTokens.inputDecoration.copyWith(prefixText: r'$  '),
      ),
    );
  }
}

class _PayrollSetupFieldFrame extends StatelessWidget {
  final String label;
  final Widget child;

  const _PayrollSetupFieldFrame({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _PayrollTokens.dialogFieldLabel),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
