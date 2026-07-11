part of '../payroll_screen.dart';

class _PayrollTabContentConsumer extends StatelessWidget {
  final PayrollController controller;
  final _EmployeeChanged onEmployeeChanged;

  const _PayrollTabContentConsumer({
    required this.controller,
    required this.onEmployeeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _PayrollProcessingView(
      controller: controller,
      onEmployeeChanged: onEmployeeChanged,
    );
  }
}

class _EmployeesTabContentConsumer extends StatelessWidget {
  final PayrollController controller;
  final Future<void> Function() onCreateEmployee;
  final ValueChanged<String> onRemoveEmployee;
  final _EmployeeChanged onEmployeeChanged;

  const _EmployeesTabContentConsumer({
    required this.controller,
    required this.onCreateEmployee,
    required this.onRemoveEmployee,
    required this.onEmployeeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        final PayrollViewState state = controller.state;
        return _EmployeesManagementView(
          state: state,
          onCreateEmployee: onCreateEmployee,
          onRemoveEmployee: onRemoveEmployee,
          onEmployeeChanged: onEmployeeChanged,
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
  final _EmployeeChanged onEmployeeChanged;

  const _PayrollProcessingView({
    required this.controller,
    required this.onEmployeeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _PayrollSetupCardConsumer(controller: controller),
        const SizedBox(height: 18),
        _EmployeePayrollListConsumer(
          controller: controller,
          onEmployeeChanged: onEmployeeChanged,
        ),
      ],
    );
  }
}

class _PayrollSetupCardConsumer extends StatefulWidget {
  final PayrollController controller;

  const _PayrollSetupCardConsumer({required this.controller});

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
    return _PayrollSetupCard(state: _state);
  }
}

class _EmployeePayrollListConsumer extends StatefulWidget {
  final PayrollController controller;
  final _EmployeeChanged onEmployeeChanged;

  const _EmployeePayrollListConsumer({
    required this.controller,
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
      onEmployeeChanged: widget.onEmployeeChanged,
    );
  }
}

bool _setupStateChanged(PayrollViewState previous, PayrollViewState next) {
  final PayrollRecord previousPayroll = previous.payroll;
  final PayrollRecord nextPayroll = next.payroll;

  return previous.balance != next.balance ||
      previous.payPeriodTotalPay != next.payPeriodTotalPay ||
      previousPayroll.unconfirmedEmployeeCount !=
          nextPayroll.unconfirmedEmployeeCount;
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
      previous.linkW4 == next.linkW4 &&
      _sameEmployeePayrollSetup(previous.payrollSetup, next.payrollSetup) &&
      previous.payrollAction == next.payrollAction &&
      previous.isPayrollConfirmed == next.isPayrollConfirmed;
}

bool _sameEmployeePayrollSetup(
  EmployeePayrollSetup? previous,
  EmployeePayrollSetup? next,
) {
  if (identical(previous, next)) return true;
  if (previous == null || next == null) return false;

  return previous.schedule == next.schedule &&
      previous.weekday == next.weekday &&
      previous.paidAfterDays == next.paidAfterDays &&
      previous.remindAfterDays == next.remindAfterDays &&
      previous.rate == next.rate;
}
