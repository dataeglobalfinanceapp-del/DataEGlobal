part of '../payroll_screen.dart';

class _PayrollSettingsScreen extends StatelessWidget {
  final PayrollController controller;

  const _PayrollSettingsScreen({required this.controller});

  Future<void> _openSetupForm(BuildContext context, PayrollEmployee employee) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => _PayrollEmployeeSetupScreen(
          employee: employee,
          onSaveSetting: controller.updateEmployeePayrollSetting,
          findNextMissingEmployee: _findNextMissingEmployeeAfter,
        ),
      ),
    );
  }

  PayrollEmployee? _findNextMissingEmployeeAfter(String employeeId) {
    final List<PayrollEmployee> employees = controller.state.payroll.employees;
    final int currentIndex = employees.indexWhere(
      (PayrollEmployee employee) => employee.id == employeeId,
    );
    if (currentIndex == -1) return null;

    for (int index = currentIndex + 1; index < employees.length; index += 1) {
      final PayrollEmployee employee = employees[index];
      if (employee.payrollSetting == null) return employee;
    }
    return null;
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
        listenable: controller,
        builder: (BuildContext context, Widget? child) {
          final PayrollViewState state = controller.state;
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<PayrollEmployee> employees = state.payroll.employees;
          return ListView(
            padding: _PayrollTokens.pagePadding,
            children: <Widget>[
              if (employees.isEmpty)
                Container(
                  decoration: _PayrollTokens.panelDecoration,
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                  child: const Text(
                    'No employees found.',
                    style: _PayrollTokens.helperText,
                  ),
                )
              else ...<Widget>[
                _PayrollSetupWarning(
                  missingSetupCount: employees
                      .where(
                        (PayrollEmployee employee) =>
                            employee.payrollSetting == null,
                      )
                      .length,
                ),
                for (int index = 0; index < employees.length; index += 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PayrollEmployeeSettingsListCard(
                      key: ValueKey<String>(
                        'payroll.settings.card.${employees[index].id}',
                      ),
                      employee: employees[index],
                      onOpenSetup: () =>
                          _openSetupForm(context, employees[index]),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PayrollSetupWarning extends StatelessWidget {
  final int missingSetupCount;

  const _PayrollSetupWarning({required this.missingSetupCount});

  @override
  Widget build(BuildContext context) {
    if (missingSetupCount == 0) return const SizedBox.shrink();

    final String employeeLabel = missingSetupCount == 1
        ? 'employee has'
        : 'employees have';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _PayrollTokens.warningBackground,
          borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.warning_amber_rounded,
              color: _PayrollTokens.warning,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$missingSetupCount $employeeLabel not set up payroll.',
                style: _PayrollTokens.cautionText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayrollEmployeeSettingsListCard extends StatelessWidget {
  final PayrollEmployee employee;
  final VoidCallback onOpenSetup;

  const _PayrollEmployeeSettingsListCard({
    super.key,
    required this.employee,
    required this.onOpenSetup,
  });

  @override
  Widget build(BuildContext context) {
    final String status = employee.payrollSetting?.schedule.label ?? 'None';
    final bool isMissingSetup = employee.payrollSetting == null;

    return Container(
      decoration: _PayrollTokens.panelDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isMissingSetup
                    ? _PayrollTokens.error
                    : _PayrollTokens.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: ValueKey<String>('payroll.settings.${employee.id}.openSetup'),
            tooltip: 'Edit payroll setup',
            onPressed: onOpenSetup,
            icon: const Icon(Icons.settings_outlined),
            color: _PayrollTokens.textMuted,
          ),
        ],
      ),
    );
  }
}

class _PayrollEmployeeSetupScreen extends StatefulWidget {
  final PayrollEmployee employee;
  final Future<void> Function(String id, EmployeePayrollSetting setting)
  onSaveSetting;
  final PayrollEmployee? Function(String employeeId) findNextMissingEmployee;

  const _PayrollEmployeeSetupScreen({
    required this.employee,
    required this.onSaveSetting,
    required this.findNextMissingEmployee,
  });

  @override
  State<_PayrollEmployeeSetupScreen> createState() =>
      _PayrollEmployeeSetupScreenState();
}

class _PayrollEmployeeSetupScreenState
    extends State<_PayrollEmployeeSetupScreen> {
  late final DateTime? _dateHire;
  late EmployeePayrollSetting? _setting;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dateHire = PayrollPeriodCalculator.parseEmployeeDate(
      widget.employee.dateHire,
    );
    _setting =
        widget.employee.payrollSetting ??
        PayrollPeriodCalculator.defaultSettingForDateHire(
          widget.employee.dateHire,
        );
  }

  void _updateDraft(EmployeePayrollSetting setting) {
    setState(() => _setting = setting);
  }

  Future<void> _save() async {
    final EmployeePayrollSetting? setting = _setting;
    if (setting == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSaveSetting(widget.employee.id, setting);
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Payroll setup saved')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _openNextEmployee() {
    final PayrollEmployee? nextEmployee = widget.findNextMissingEmployee(
      widget.employee.id,
    );
    if (nextEmployee == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('No more employee to setup')),
        );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => _PayrollEmployeeSetupScreen(
          employee: nextEmployee,
          onSaveSetting: widget.onSaveSetting,
          findNextMissingEmployee: widget.findNextMissingEmployee,
        ),
      ),
    );
  }

  Future<void> _pickFirstPeriodEndDate() async {
    final DateTime? dateHire = _dateHire;
    final EmployeePayrollSetting? setting = _setting;
    if (dateHire == null || setting == null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: setting.firstPeriodEndDate.isBefore(dateHire)
          ? dateHire
          : setting.firstPeriodEndDate,
      firstDate: dateHire,
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Choose first period end date',
    );
    if (picked == null || !mounted) return;

    final DateTime pickedDate = PayrollPeriodCalculator.dateOnly(picked);
    _updateDraft(
      setting.copyWith(
        firstPeriodEndDate: pickedDate,
        endingDay: EmployeePayrollEndingDay.fromDate(pickedDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EmployeePayrollSetting? setting = _setting;
    final DateTime? dateHire = _dateHire;
    final bool canEditPeriod = dateHire != null && setting != null;
    ValueChanged<EmployeePayrollSchedule>? onScheduleChanged;
    ValueChanged<EmployeePayrollEndingDay>? onEndingDayChanged;
    ValueChanged<EmployeePayDateSetting>? onPayDateSettingChanged;
    ValueChanged<EmployeeProcessPayrollSetting>? onProcessPayrollSettingChanged;

    if (dateHire != null && setting != null) {
      final EmployeePayrollSetting editableSetting = setting;
      final DateTime editableDateHire = dateHire;
      onScheduleChanged = (EmployeePayrollSchedule schedule) {
        _updateDraft(editableSetting.copyWith(schedule: schedule));
      };
      onEndingDayChanged = (EmployeePayrollEndingDay endingDay) {
        _updateDraft(
          editableSetting.copyWith(
            endingDay: endingDay,
            firstPeriodEndDate:
                PayrollPeriodCalculator.firstPeriodEndDateForEndingDay(
                  hireDate: editableDateHire,
                  endingDay: endingDay,
                ),
          ),
        );
      };
      onPayDateSettingChanged = (EmployeePayDateSetting payDateSetting) {
        _updateDraft(editableSetting.copyWith(payDateSetting: payDateSetting));
      };
      onProcessPayrollSettingChanged =
          (EmployeeProcessPayrollSetting processPayrollSetting) {
            _updateDraft(
              editableSetting.copyWith(
                processPayrollSetting: processPayrollSetting,
              ),
            );
          };
    }

    return Scaffold(
      backgroundColor: _PayrollTokens.screenBackground,
      appBar: AppBar(
        backgroundColor: _PayrollTokens.surface,
        elevation: 0,
        title: const Text('Payroll Setup', style: _PayrollTokens.appBarTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: _PayrollTokens.pagePadding,
        children: <Widget>[
          Container(
            decoration: _PayrollTokens.panelDecoration,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.employee.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _PayrollTokens.employeeName,
                ),
                const SizedBox(height: 6),
                Text(
                  'Date Hire: ${widget.employee.dateHire.trim().isEmpty ? '-' : widget.employee.dateHire}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _PayrollTokens.helperText,
                ),
                const SizedBox(height: 18),
                _PayrollSetupFormFields(
                  setting: setting,
                  enabled: canEditPeriod,
                  onScheduleChanged: onScheduleChanged,
                  onEndingDayChanged: onEndingDayChanged,
                  onFirstPeriodEndDateTap: canEditPeriod
                      ? _pickFirstPeriodEndDate
                      : null,
                  onPayDateSettingChanged: onPayDateSettingChanged,
                  onProcessPayrollSettingChanged:
                      onProcessPayrollSettingChanged,
                ),
                const SizedBox(height: 22),
                _PayrollSetupActions(
                  employeeId: widget.employee.id,
                  canSave: canEditPeriod && !_isSaving,
                  isSaving: _isSaving,
                  onSave: _save,
                  onNextEmployee: _openNextEmployee,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollSetupActions extends StatelessWidget {
  final String employeeId;
  final bool canSave;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onNextEmployee;

  const _PayrollSetupActions({
    required this.employeeId,
    required this.canSave,
    required this.isSaving,
    required this.onSave,
    required this.onNextEmployee,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          OutlinedButton(
            key: ValueKey<String>('payroll.settings.$employeeId.nextEmployee'),
            onPressed: onNextEmployee,
            style: OutlinedButton.styleFrom(
              foregroundColor: _PayrollTokens.textMuted,
              side: const BorderSide(color: _PayrollTokens.border),
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  _PayrollTokens.controlRadius,
                ),
              ),
            ),
            child: const Text('Next Employee'),
          ),
          FilledButton(
            key: ValueKey<String>('payroll.settings.$employeeId.save'),
            onPressed: canSave ? onSave : null,
            style: FilledButton.styleFrom(
              backgroundColor: _PayrollTokens.tabSelected,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _PayrollTokens.border,
              disabledForegroundColor: _PayrollTokens.textMuted,
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  _PayrollTokens.controlRadius,
                ),
              ),
            ),
            child: Text(isSaving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _PayrollSetupFormFields extends StatelessWidget {
  final EmployeePayrollSetting? setting;
  final bool enabled;
  final ValueChanged<EmployeePayrollSchedule>? onScheduleChanged;
  final ValueChanged<EmployeePayrollEndingDay>? onEndingDayChanged;
  final VoidCallback? onFirstPeriodEndDateTap;
  final ValueChanged<EmployeePayDateSetting>? onPayDateSettingChanged;
  final ValueChanged<EmployeeProcessPayrollSetting>?
  onProcessPayrollSettingChanged;

  const _PayrollSetupFormFields({
    required this.setting,
    required this.enabled,
    required this.onScheduleChanged,
    required this.onEndingDayChanged,
    required this.onFirstPeriodEndDateTap,
    required this.onPayDateSettingChanged,
    required this.onProcessPayrollSettingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final EmployeePayrollSetting? currentSetting = setting;

    return Column(
      children: <Widget>[
        _PayrollSettingsDropdownField<EmployeePayrollSchedule>(
          label: 'Payroll Schedule',
          value: currentSetting?.schedule ?? EmployeePayrollSchedule.biWeekly,
          options: EmployeePayrollSchedule.values,
          optionLabel: (EmployeePayrollSchedule schedule) => schedule.label,
          onChanged: enabled ? onScheduleChanged : null,
        ),
        const SizedBox(height: 16),
        _PayrollSettingsDropdownField<EmployeePayrollEndingDay>(
          label: 'Ending Day',
          value: currentSetting?.endingDay ?? EmployeePayrollEndingDay.sunday,
          options: EmployeePayrollEndingDay.values,
          optionLabel: (EmployeePayrollEndingDay day) => day.label,
          onChanged: enabled ? onEndingDayChanged : null,
        ),
        const SizedBox(height: 16),
        _PayrollSettingsDateField(
          label: 'First Period End Date',
          value: currentSetting == null
              ? '--/--/--'
              : PayrollPeriodCalculator.formatShortDate(
                  currentSetting.firstPeriodEndDate,
                ),
          enabled: enabled,
          onTap: enabled ? onFirstPeriodEndDateTap : null,
        ),
        const SizedBox(height: 16),
        _PayrollSettingsDropdownField<EmployeePayDateSetting>(
          label: 'Pay Date setting',
          value:
              currentSetting?.payDateSetting ??
              EmployeePayDateSetting.afterPeriodEnd,
          options: EmployeePayDateSetting.values,
          optionLabel: (EmployeePayDateSetting value) => value.label,
          onChanged: enabled ? onPayDateSettingChanged : null,
        ),
        const SizedBox(height: 16),
        _PayrollSettingsDropdownField<EmployeeProcessPayrollSetting>(
          label: 'Process Payroll setting',
          value:
              currentSetting?.processPayrollSetting ??
              EmployeeProcessPayrollSetting.manualReview,
          options: EmployeeProcessPayrollSetting.values,
          optionLabel: (EmployeeProcessPayrollSetting value) => value.label,
          onChanged: enabled ? onProcessPayrollSettingChanged : null,
        ),
      ],
    );
  }
}

class _PayrollSettingsDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;
  final String Function(T value) optionLabel;
  final ValueChanged<T>? onChanged;

  const _PayrollSettingsDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _PayrollSettingsFieldFrame(
      label: label,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down),
        decoration: _PayrollTokens.inputDecoration.copyWith(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        style: _PayrollTokens.inputText.copyWith(fontSize: 16),
        items: options
            .map(
              (T option) => DropdownMenuItem<T>(
                value: option,
                child: Text(
                  optionLabel(option),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged == null
            ? null
            : (T? nextValue) {
                if (nextValue == null) return;
                onChanged!(nextValue);
              },
      ),
    );
  }
}

class _PayrollSettingsDateField extends StatefulWidget {
  final String label;
  final String value;
  final bool enabled;
  final VoidCallback? onTap;

  const _PayrollSettingsDateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PayrollSettingsDateField> createState() =>
      _PayrollSettingsDateFieldState();
}

class _PayrollSettingsDateFieldState extends State<_PayrollSettingsDateField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _PayrollSettingsDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PayrollSettingsFieldFrame(
      label: widget.label,
      child: TextFormField(
        key: ValueKey<String>('payroll.settings.${widget.label}'),
        controller: _controller,
        readOnly: true,
        enabled: widget.enabled,
        onTap: widget.onTap,
        style: _PayrollTokens.inputText.copyWith(fontSize: 16),
        decoration: _PayrollTokens.inputDecoration.copyWith(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
      ),
    );
  }
}

class _PayrollSettingsFieldFrame extends StatelessWidget {
  final String label;
  final Widget child;

  const _PayrollSettingsFieldFrame({required this.label, required this.child});

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
