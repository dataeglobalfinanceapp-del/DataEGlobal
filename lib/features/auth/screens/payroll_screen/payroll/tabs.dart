part of '../payroll_screen.dart';

class _PayrollTabContentConsumer extends StatelessWidget {
  final PayrollController controller;
  final VoidCallback onPickPayDate;
  final VoidCallback onChooseProcessDays;
  final ValueChanged<PayrollSchedule> onScheduleChanged;
  final VoidCallback onAddEmployee;
  final ValueChanged<String> onRemoveEmployee;
  final _EmployeeChanged onEmployeeChanged;
  final VoidCallback onSavePayroll;

  const _PayrollTabContentConsumer({
    required this.controller,
    required this.onPickPayDate,
    required this.onChooseProcessDays,
    required this.onScheduleChanged,
    required this.onAddEmployee,
    required this.onRemoveEmployee,
    required this.onEmployeeChanged,
    required this.onSavePayroll,
  });

  @override
  Widget build(BuildContext context) {
    return _PayrollProcessingView(
      controller: controller,
      onPickPayDate: onPickPayDate,
      onChooseProcessDays: onChooseProcessDays,
      onScheduleChanged: onScheduleChanged,
      onAddEmployee: onAddEmployee,
      onRemoveEmployee: onRemoveEmployee,
      onEmployeeChanged: onEmployeeChanged,
      onSavePayroll: onSavePayroll,
    );
  }
}

class _EmployeesTabContentConsumer extends StatelessWidget {
  final PayrollController controller;
  final VoidCallback onAddEmployee;
  final ValueChanged<String> onRemoveEmployee;
  final _EmployeeChanged onEmployeeChanged;
  final VoidCallback onSavePayroll;

  const _EmployeesTabContentConsumer({
    required this.controller,
    required this.onAddEmployee,
    required this.onRemoveEmployee,
    required this.onEmployeeChanged,
    required this.onSavePayroll,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        final PayrollViewState state = controller.state;
        return _EmployeesManagementView(
          state: state,
          onAddEmployee: onAddEmployee,
          onRemoveEmployee: onRemoveEmployee,
          onEmployeeChanged: onEmployeeChanged,
          onSavePayroll: onSavePayroll,
        );
      },
    );
  }
}

class _PayrollTabCard extends StatelessWidget {
  final _PayrollTab selectedTab;
  final ValueChanged<_PayrollTab> onChanged;

  const _PayrollTabCard({required this.selectedTab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _PayrollTokens.panelDecoration,
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: <Widget>[
          for (final _PayrollTab tab in _PayrollTab.values)
            Expanded(
              child: _PayrollTabButton(
                tab: tab,
                isSelected: selectedTab == tab,
                onTap: () => onChanged(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _PayrollTabButton extends StatelessWidget {
  final _PayrollTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _PayrollTabButton({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected
        ? _PayrollTokens.tabSelected
        : _PayrollTokens.textMuted;

    return Material(
      key: ValueKey<String>('payroll.tab.${tab.name}'),
      color: _PayrollTokens.surface,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 70,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? _PayrollTokens.tabSelected
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(tab.icon, color: color, size: 27),
                  const SizedBox(width: 10),
                  Text(
                    tab.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PayrollProcessingView extends StatelessWidget {
  final PayrollController controller;
  final VoidCallback onPickPayDate;
  final VoidCallback onChooseProcessDays;
  final ValueChanged<PayrollSchedule> onScheduleChanged;
  final VoidCallback onAddEmployee;
  final ValueChanged<String> onRemoveEmployee;
  final _EmployeeChanged onEmployeeChanged;
  final VoidCallback onSavePayroll;

  const _PayrollProcessingView({
    required this.controller,
    required this.onPickPayDate,
    required this.onChooseProcessDays,
    required this.onScheduleChanged,
    required this.onAddEmployee,
    required this.onRemoveEmployee,
    required this.onEmployeeChanged,
    required this.onSavePayroll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _PayrollSetupCardConsumer(
          controller: controller,
          onPickPayDate: onPickPayDate,
          onChooseProcessDays: onChooseProcessDays,
          onScheduleChanged: onScheduleChanged,
        ),
        const SizedBox(height: 18),
        _EmployeePayrollListConsumer(
          controller: controller,
          onAddEmployee: onAddEmployee,
          onRemoveEmployee: onRemoveEmployee,
          onEmployeeChanged: onEmployeeChanged,
        ),
        const SizedBox(height: 16),
        _SavePayrollButtonConsumer(
          controller: controller,
          onSavePayroll: onSavePayroll,
        ),
      ],
    );
  }
}

class _PayrollSetupCardConsumer extends StatefulWidget {
  final PayrollController controller;
  final VoidCallback onPickPayDate;
  final VoidCallback onChooseProcessDays;
  final ValueChanged<PayrollSchedule> onScheduleChanged;

  const _PayrollSetupCardConsumer({
    required this.controller,
    required this.onPickPayDate,
    required this.onChooseProcessDays,
    required this.onScheduleChanged,
  });

  @override
  State<_PayrollSetupCardConsumer> createState() =>
      _PayrollSetupCardConsumerState();
}

class _PayrollSetupCardConsumerState extends State<_PayrollSetupCardConsumer> {
  late PayrollViewState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.controller.state;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _PayrollSetupCardConsumer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_handleControllerChanged);
    _state = widget.controller.state;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final PayrollViewState nextState = widget.controller.state;
    if (!_setupStateChanged(_state, nextState)) return;

    setState(() => _state = nextState);
  }

  @override
  Widget build(BuildContext context) {
    return _PayrollSetupCard(
      state: _state,
      onPickPayDate: widget.onPickPayDate,
      onChooseProcessDays: widget.onChooseProcessDays,
      onScheduleChanged: widget.onScheduleChanged,
    );
  }
}

class _EmployeePayrollListConsumer extends StatefulWidget {
  final PayrollController controller;
  final VoidCallback onAddEmployee;
  final ValueChanged<String> onRemoveEmployee;
  final _EmployeeChanged onEmployeeChanged;

  const _EmployeePayrollListConsumer({
    required this.controller,
    required this.onAddEmployee,
    required this.onRemoveEmployee,
    required this.onEmployeeChanged,
  });

  @override
  State<_EmployeePayrollListConsumer> createState() =>
      _EmployeePayrollListConsumerState();
}

class _EmployeePayrollListConsumerState
    extends State<_EmployeePayrollListConsumer> {
  late PayrollViewState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.controller.state;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _EmployeePayrollListConsumer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_handleControllerChanged);
    _state = widget.controller.state;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final PayrollViewState nextState = widget.controller.state;
    if (!_employeeListStateChanged(_state, nextState)) return;

    setState(() => _state = nextState);
  }

  @override
  Widget build(BuildContext context) {
    return _EmployeePayrollList(
      state: _state,
      onAddEmployee: widget.onAddEmployee,
      onRemoveEmployee: widget.onRemoveEmployee,
      onEmployeeChanged: widget.onEmployeeChanged,
    );
  }
}

class _SavePayrollButtonConsumer extends StatefulWidget {
  final PayrollController controller;
  final VoidCallback onSavePayroll;

  const _SavePayrollButtonConsumer({
    required this.controller,
    required this.onSavePayroll,
  });

  @override
  State<_SavePayrollButtonConsumer> createState() =>
      _SavePayrollButtonConsumerState();
}

class _SavePayrollButtonConsumerState
    extends State<_SavePayrollButtonConsumer> {
  late bool _isSaving;

  @override
  void initState() {
    super.initState();
    _isSaving = widget.controller.state.isSaving;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _SavePayrollButtonConsumer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_handleControllerChanged);
    _isSaving = widget.controller.state.isSaving;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final bool nextIsSaving = widget.controller.state.isSaving;
    if (_isSaving == nextIsSaving) return;

    setState(() => _isSaving = nextIsSaving);
  }

  @override
  Widget build(BuildContext context) {
    return _SavePayrollButton(
      isSaving: _isSaving,
      onPressed: _isSaving ? null : widget.onSavePayroll,
    );
  }
}

bool _setupStateChanged(PayrollViewState previous, PayrollViewState next) {
  final PayrollRecord previousPayroll = previous.payroll;
  final PayrollRecord nextPayroll = next.payroll;

  return previous.balance != next.balance ||
      previous.payPeriodTotalPay != next.payPeriodTotalPay ||
      previousPayroll.schedule != nextPayroll.schedule ||
      previousPayroll.processDaysBefore != nextPayroll.processDaysBefore ||
      !_dateOnly(
        previousPayroll.payDate,
      ).isAtSameMomentAs(_dateOnly(nextPayroll.payDate));
}

bool _employeeListStateChanged(
  PayrollViewState previous,
  PayrollViewState next,
) {
  return !_samePayrollEmployees(
    previous.payroll.employees,
    next.payroll.employees,
  );
}

bool _samePayrollEmployees(
  List<PayrollEmployee> previous,
  List<PayrollEmployee> next,
) {
  if (identical(previous, next)) return true;
  if (previous.length != next.length) return false;

  for (int index = 0; index < previous.length; index += 1) {
    if (!_samePayrollEmployee(previous[index], next[index])) return false;
  }
  return true;
}

bool _samePayrollEmployee(PayrollEmployee previous, PayrollEmployee next) {
  return previous.id == next.id &&
      previous.name == next.name &&
      previous.rate == next.rate &&
      previous.regularHours == next.regularHours &&
      previous.overtimeHours == next.overtimeHours &&
      previous.commission == next.commission &&
      previous.tips == next.tips &&
      previous.birthday == next.birthday &&
      previous.phone == next.phone &&
      previous.address == next.address &&
      previous.jobType == next.jobType &&
      previous.dateHire == next.dateHire &&
      previous.payMethod == next.payMethod &&
      previous.linkW4 == next.linkW4;
}
