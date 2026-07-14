part of '../payroll_screen.dart';

class _PayrollSettingsScreen extends StatelessWidget {
  final PayrollController controller;

  const _PayrollSettingsScreen({required this.controller});

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
          if (employees.isEmpty) {
            return ListView(
              padding: _PayrollTokens.pagePadding,
              children: <Widget>[
                Container(
                  decoration: _PayrollTokens.panelDecoration,
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                  child: const Text(
                    'No employees found.',
                    style: _PayrollTokens.helperText,
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: _PayrollTokens.pagePadding,
            itemCount: employees.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PayrollEmployeeSettingsCard(
                  key: ValueKey<String>(
                    'payroll.settings.card.${employees[index].id}',
                  ),
                  employee: employees[index],
                  onSettingChanged: controller.updateEmployeePayrollSetting,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PayrollEmployeeSettingsCard extends StatelessWidget {
  final PayrollEmployee employee;
  final Future<void> Function(String id, EmployeePayrollSetting setting)
  onSettingChanged;

  const _PayrollEmployeeSettingsCard({
    super.key,
    required this.employee,
    required this.onSettingChanged,
  });

  Future<void> _updateSetting(EmployeePayrollSetting setting) {
    return onSettingChanged(employee.id, setting);
  }

  Future<void> _pickFirstPeriodEndDate(
    BuildContext context,
    EmployeePayrollSetting setting,
    DateTime dateHire,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: setting.firstPeriodEndDate.isBefore(dateHire)
          ? dateHire
          : setting.firstPeriodEndDate,
      firstDate: dateHire,
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Choose first period end date',
    );
    if (picked == null || !context.mounted) return;

    final DateTime pickedDate = PayrollPeriodCalculator.dateOnly(picked);
    await _updateSetting(
      setting.copyWith(
        firstPeriodEndDate: pickedDate,
        endingDay: EmployeePayrollEndingDay.fromDate(pickedDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? dateHire = PayrollPeriodCalculator.parseEmployeeDate(
      employee.dateHire,
    );
    final EmployeePayrollSetting? setting =
        employee.payrollSetting ??
        PayrollPeriodCalculator.defaultSettingForDateHire(employee.dateHire);
    final bool canEditPeriod = dateHire != null && setting != null;

    return Container(
      decoration: _PayrollTokens.panelDecoration,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            employee.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _PayrollTokens.employeeName,
          ),
          const SizedBox(height: 4),
          Text(
            'Date Hire: ${employee.dateHire.trim().isEmpty ? '-' : employee.dateHire}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _PayrollTokens.helperText,
          ),
          const SizedBox(height: 16),
          _PayrollSettingsFieldGrid(
            fields: <Widget>[
              _PayrollSettingsDropdownField<EmployeePayrollSchedule>(
                label: 'Payroll Schedule',
                value: setting?.schedule ?? EmployeePayrollSchedule.biWeekly,
                options: EmployeePayrollSchedule.values,
                optionLabel: (EmployeePayrollSchedule schedule) =>
                    schedule.label,
                onChanged: canEditPeriod
                    ? (EmployeePayrollSchedule schedule) {
                        _updateSetting(setting.copyWith(schedule: schedule));
                      }
                    : null,
              ),
              _PayrollSettingsDropdownField<EmployeePayrollEndingDay>(
                label: 'Ending Day',
                value: setting?.endingDay ?? EmployeePayrollEndingDay.sunday,
                options: EmployeePayrollEndingDay.values,
                optionLabel: (EmployeePayrollEndingDay day) => day.label,
                onChanged: canEditPeriod
                    ? (EmployeePayrollEndingDay endingDay) {
                        _updateSetting(
                          setting.copyWith(
                            endingDay: endingDay,
                            firstPeriodEndDate:
                                PayrollPeriodCalculator.firstPeriodEndDateForEndingDay(
                                  hireDate: dateHire,
                                  endingDay: endingDay,
                                ),
                          ),
                        );
                      }
                    : null,
              ),
              _PayrollSettingsDateField(
                label: 'First Period End Date',
                value: setting == null
                    ? '--/--/--'
                    : PayrollPeriodCalculator.formatShortDate(
                        setting.firstPeriodEndDate,
                      ),
                enabled: canEditPeriod,
                onTap: canEditPeriod
                    ? () => _pickFirstPeriodEndDate(context, setting, dateHire)
                    : null,
              ),
              _PayrollSettingsDropdownField<EmployeePayDateSetting>(
                label: 'Pay Date setting',
                value:
                    setting?.payDateSetting ??
                    EmployeePayDateSetting.afterPeriodEnd,
                options: EmployeePayDateSetting.values,
                optionLabel: (EmployeePayDateSetting value) => value.label,
                onChanged: canEditPeriod
                    ? (EmployeePayDateSetting payDateSetting) {
                        _updateSetting(
                          setting.copyWith(payDateSetting: payDateSetting),
                        );
                      }
                    : null,
              ),
              _PayrollSettingsDropdownField<EmployeeProcessPayrollSetting>(
                label: 'Process Payroll setting',
                value:
                    setting?.processPayrollSetting ??
                    EmployeeProcessPayrollSetting.manualReview,
                options: EmployeeProcessPayrollSetting.values,
                optionLabel: (EmployeeProcessPayrollSetting value) =>
                    value.label,
                onChanged: canEditPeriod
                    ? (EmployeeProcessPayrollSetting processPayrollSetting) {
                        _updateSetting(
                          setting.copyWith(
                            processPayrollSetting: processPayrollSetting,
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayrollSettingsFieldGrid extends StatelessWidget {
  final List<Widget> fields;

  const _PayrollSettingsFieldGrid({required this.fields});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 560 ? 2 : 1;
        const double gap = 14;
        final double width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: 14,
          children: <Widget>[
            for (final Widget field in fields)
              SizedBox(width: width, child: field),
          ],
        );
      },
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
        decoration: _PayrollTokens.inputDecoration,
        style: _PayrollTokens.inputText,
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

class _PayrollSettingsDateField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return _PayrollSettingsFieldFrame(
      label: label,
      child: TextFormField(
        key: ValueKey<String>('payroll.settings.$label'),
        initialValue: value,
        readOnly: true,
        enabled: enabled,
        onTap: onTap,
        style: _PayrollTokens.inputText,
        decoration: _PayrollTokens.inputDecoration.copyWith(
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
