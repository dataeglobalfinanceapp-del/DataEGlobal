import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/money_formatter.dart';

import 'payroll_controller.dart';
import 'payroll_models.dart';

typedef _EmployeeChanged =
    void Function(
      String id, {
      String? name,
      double? rate,
      double? regularHours,
      double? overtimeHours,
      double? commission,
      double? tips,
      String? birthday,
      String? phone,
      String? address,
      String? dateHire,
      String? jobType,
      String? linkW4,
    });

enum _PayrollTab {
  payroll('Payroll', Icons.people_alt_outlined),
  employees('Employees', Icons.groups_2_outlined);

  final String label;
  final IconData icon;

  const _PayrollTab(this.label, this.icon);
}

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  static const List<int> _processDayOptions = <int>[1, 2, 3, 5, 7, 10, 14];

  late final PayrollController _controller;
  _PayrollTab _selectedTab = _PayrollTab.payroll;

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

  Future<void> _openAddEmployeeDialog() async {
    final PayrollEmployee? employee = await showDialog<PayrollEmployee>(
      context: context,
      builder: (BuildContext context) => const _AddEmployeeDialog(),
    );
    if (employee == null || !mounted) return;

    await _controller.addEmployeeRecord(employee);
  }

  void _selectTab(_PayrollTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
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
          if (_controller.state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return child!;
        },
        child: RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView(
            padding: _PayrollTokens.pagePadding,
            children: <Widget>[
              _PayrollTabCard(selectedTab: _selectedTab, onChanged: _selectTab),
              const SizedBox(height: 16),
              if (_selectedTab == _PayrollTab.payroll)
                _PayrollTabContentConsumer(
                  controller: _controller,
                  onPickPayDate: _pickPayDate,
                  onChooseProcessDays: _chooseProcessDays,
                  onScheduleChanged: _controller.setSchedule,
                  onAddEmployee: _controller.addEmployee,
                  onRemoveEmployee: _controller.removeEmployee,
                  onEmployeeChanged: _controller.updateEmployee,
                  onSavePayroll: _savePayroll,
                )
              else
                _EmployeesTabContentConsumer(
                  controller: _controller,
                  onAddEmployee: _openAddEmployeeDialog,
                  onRemoveEmployee: _controller.removeEmployee,
                  onEmployeeChanged: _controller.updateEmployee,
                  onSavePayroll: _savePayroll,
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _EmployeesManagementView extends StatefulWidget {
  final PayrollViewState state;
  final VoidCallback onAddEmployee;
  final ValueChanged<String> onRemoveEmployee;
  final _EmployeeChanged onEmployeeChanged;
  final VoidCallback onSavePayroll;

  const _EmployeesManagementView({
    required this.state,
    required this.onAddEmployee,
    required this.onRemoveEmployee,
    required this.onEmployeeChanged,
    required this.onSavePayroll,
  });

  @override
  State<_EmployeesManagementView> createState() =>
      _EmployeesManagementViewState();
}

class _EmployeesManagementViewState extends State<_EmployeesManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedEmployeeId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _syncSelectedEmployee();
  }

  @override
  void didUpdateWidget(covariant _EmployeesManagementView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSelectedEmployee();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  void _syncSelectedEmployee() {
    final List<PayrollEmployee> employees = widget.state.payroll.employees;
    if (employees.isEmpty) {
      _selectedEmployeeId = null;
      return;
    }

    final bool hasSelected = employees.any(
      (PayrollEmployee employee) => employee.id == _selectedEmployeeId,
    );
    if (!hasSelected) {
      _selectedEmployeeId = employees.first.id;
    }
  }

  void _selectEmployee(PayrollEmployee employee) {
    setState(() => _selectedEmployeeId = employee.id);
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return _EmployeeInformationDialog(
          employee: employee,
          onEmployeeChanged: widget.onEmployeeChanged,
          onRemoveEmployee: widget.onRemoveEmployee,
        );
      },
    );
  }

  void _addEmployee() {
    widget.onAddEmployee();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<PayrollEmployee> employees = widget.state.payroll.employees;
    final String query = _searchController.text.trim().toLowerCase();
    final List<PayrollEmployee> filteredEmployees = employees
        .where(
          (PayrollEmployee employee) =>
              query.isEmpty || employee.name.toLowerCase().contains(query),
        )
        .toList(growable: false);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget listCard = _EmployeeListCard(
          employees: filteredEmployees,
          selectedEmployeeId: _selectedEmployeeId,
          searchController: _searchController,
          totalEmployeeCount: employees.length,
          onSelectEmployee: _selectEmployee,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _EmployeesHeader(onAddEmployee: _addEmployee),
            const SizedBox(height: 18),
            listCard,
          ],
        );
      },
    );
  }
}

class _EmployeesHeader extends StatelessWidget {
  final VoidCallback onAddEmployee;

  const _EmployeesHeader({required this.onAddEmployee});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 460;
        const Widget title = Text(
          'Employees',
          style: _PayrollTokens.employeesTitle,
        );
        final Widget button = FilledButton.icon(
          onPressed: onAddEmployee,
          icon: const Icon(Icons.add),
          label: const Text('Add New Employee'),
          style: FilledButton.styleFrom(
            backgroundColor: _PayrollTokens.tabSelected,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_PayrollTokens.cardRadius),
            ),
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              title,
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: button),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: title),
            button,
          ],
        );
      },
    );
  }
}

class _EmployeeListCard extends StatelessWidget {
  final List<PayrollEmployee> employees;
  final String? selectedEmployeeId;
  final TextEditingController searchController;
  final int totalEmployeeCount;
  final ValueChanged<PayrollEmployee> onSelectEmployee;

  const _EmployeeListCard({
    required this.employees,
    required this.selectedEmployeeId,
    required this.searchController,
    required this.totalEmployeeCount,
    required this.onSelectEmployee,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _PayrollTokens.panelDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Employee List', style: _PayrollTokens.cardTitle),
                const SizedBox(height: 14),
                TextField(
                  key: const ValueKey<String>('payroll.employees.search'),
                  controller: searchController,
                  decoration: _PayrollTokens.searchDecoration,
                  textInputAction: TextInputAction.search,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _PayrollTokens.divider),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Text('NAME', style: _PayrollTokens.listHeader),
          ),
          if (employees.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 32),
              child: Text(
                'No employees found.',
                style: _PayrollTokens.helperText,
              ),
            )
          else
            for (final PayrollEmployee employee in employees)
              _EmployeeListRow(
                employee: employee,
                isSelected: employee.id == selectedEmployeeId,
                onTap: () => onSelectEmployee(employee),
              ),
          const Divider(height: 1, color: _PayrollTokens.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Text(
              'Showing $totalEmployeeCount ${totalEmployeeCount == 1 ? 'employee' : 'employees'}',
              style: _PayrollTokens.helperText,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeListRow extends StatelessWidget {
  final PayrollEmployee employee;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmployeeListRow({
    required this.employee,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? _PayrollTokens.selectedRow : _PayrollTokens.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _PayrollTokens.divider)),
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
              const Icon(
                Icons.chevron_right,
                color: _PayrollTokens.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeInformationDialog extends StatefulWidget {
  final PayrollEmployee employee;
  final _EmployeeChanged onEmployeeChanged;
  final ValueChanged<String> onRemoveEmployee;

  const _EmployeeInformationDialog({
    required this.employee,
    required this.onEmployeeChanged,
    required this.onRemoveEmployee,
  });

  @override
  State<_EmployeeInformationDialog> createState() =>
      _EmployeeInformationDialogState();
}

class _EmployeeInformationDialogState
    extends State<_EmployeeInformationDialog> {
  static const List<String> _jobTypes = <String>[
    'Hourly',
    'Salary',
    'Contractor',
    'Part Time',
    'Full Time',
  ];

  late PayrollEmployee _employee;
  late final TextEditingController _nameController;
  late final TextEditingController _birthdayController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _dateHireController;
  late final TextEditingController _linkW4Controller;
  late String _jobType;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _nameController = TextEditingController(text: _employee.name);
    _birthdayController = TextEditingController(text: _employee.birthday);
    _phoneController = TextEditingController(text: _employee.phone);
    _addressController = TextEditingController(text: _employee.address);
    _dateHireController = TextEditingController(text: _employee.dateHire);
    _linkW4Controller = TextEditingController(text: _employee.linkW4);
    _jobType = _jobTypes.contains(_employee.jobType)
        ? _employee.jobType
        : _jobTypes.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateHireController.dispose();
    _linkW4Controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _confirm() {
    final PayrollEmployee updated = _employee.copyWith(
      name: _nameController.text.trim().isEmpty
          ? _employee.name
          : _nameController.text.trim(),
      birthday: _birthdayController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      dateHire: _dateHireController.text.trim(),
      jobType: _jobType,
      linkW4: _linkW4Controller.text.trim(),
    );
    widget.onEmployeeChanged(
      _employee.id,
      name: updated.name,
      birthday: updated.birthday,
      phone: updated.phone,
      address: updated.address,
      dateHire: updated.dateHire,
      jobType: updated.jobType,
      linkW4: updated.linkW4,
    );
    FocusScope.of(context).unfocus();
    setState(() {
      _employee = updated;
      _isEditing = false;
    });
  }

  Future<void> _remove() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text('Are you sure you want to remove this employee?'),
          actions: <Widget>[
            TextButton(
              key: const ValueKey<String>('payroll.employeeInfo.cancelRemove'),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const ValueKey<String>('payroll.employeeInfo.confirmRemove'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    widget.onRemoveEmployee(_employee.id);
    Navigator.pop(context);
  }

  List<_EmployeeDetailData> get _details {
    return <_EmployeeDetailData>[
      _EmployeeDetailData(label: 'Full Name', value: _employee.name),
      _EmployeeDetailData(label: 'Birthday', value: _employee.birthday),
      _EmployeeDetailData(label: 'Phone', value: _employee.phone),
      _EmployeeDetailData(label: 'Address', value: _employee.address),
      _EmployeeDetailData(label: 'Date Hire', value: _employee.dateHire),
      _EmployeeDetailData(label: 'Job Type', value: _employee.jobType),
      if (_employee.linkW4.trim().isNotEmpty)
        _EmployeeDetailData(label: 'W4', value: _employee.linkW4),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: _PayrollTokens.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_PayrollTokens.cardRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: screenSize.height - 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Employee Information',
                      style: _PayrollTokens.cardTitle,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>('payroll.employeeInfo.edit'),
                    tooltip: 'Edit employee',
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit_outlined),
                    style: IconButton.styleFrom(
                      foregroundColor: _PayrollTokens.textMuted,
                      side: const BorderSide(color: _PayrollTokens.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          _PayrollTokens.controlRadius,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const ValueKey<String>('payroll.employeeInfo.close'),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: _PayrollTokens.textMuted,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: _isEditing
                    ? _EmployeeInformationEditFields(
                        nameController: _nameController,
                        birthdayController: _birthdayController,
                        phoneController: _phoneController,
                        addressController: _addressController,
                        dateHireController: _dateHireController,
                        linkW4Controller: _linkW4Controller,
                        jobType: _jobType,
                        jobTypes: _jobTypes,
                        showW4: _employee.linkW4.trim().isNotEmpty,
                        onJobTypeChanged: (String? value) {
                          if (value == null) return;
                          setState(() => _jobType = value);
                        },
                      )
                    : _EmployeeDetailGrid(details: _details),
              ),
            ),
            if (_isEditing) ...<Widget>[
              const Divider(height: 1, color: _PayrollTokens.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 112,
                        height: 48,
                        child: OutlinedButton(
                          key: const ValueKey<String>(
                            'payroll.employeeInfo.remove',
                          ),
                          onPressed: _remove,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _PayrollTokens.controlRadius,
                              ),
                            ),
                          ),
                          child: const Text('Remove'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 128,
                        height: 48,
                        child: FilledButton(
                          key: const ValueKey<String>(
                            'payroll.employeeInfo.confirm',
                          ),
                          onPressed: _confirm,
                          style: FilledButton.styleFrom(
                            backgroundColor: _PayrollTokens.tabSelected,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                _PayrollTokens.controlRadius,
                              ),
                            ),
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmployeeInformationEditFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController birthdayController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController dateHireController;
  final TextEditingController linkW4Controller;
  final String jobType;
  final List<String> jobTypes;
  final bool showW4;
  final ValueChanged<String?> onJobTypeChanged;

  const _EmployeeInformationEditFields({
    required this.nameController,
    required this.birthdayController,
    required this.phoneController,
    required this.addressController,
    required this.dateHireController,
    required this.linkW4Controller,
    required this.jobType,
    required this.jobTypes,
    required this.showW4,
    required this.onJobTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool twoColumns = constraints.maxWidth >= 520;
        const double gap = 16;
        final double fieldWidth = twoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: 16,
          children: <Widget>[
            SizedBox(
              width: fieldWidth,
              child: _EmployeeInformationTextField(
                fieldKey: const ValueKey<String>(
                  'payroll.employeeInfo.fullName',
                ),
                label: 'Full Name',
                controller: nameController,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _EmployeeInformationTextField(
                fieldKey: const ValueKey<String>(
                  'payroll.employeeInfo.birthday',
                ),
                label: 'Birthday',
                controller: birthdayController,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _EmployeeInformationTextField(
                fieldKey: const ValueKey<String>('payroll.employeeInfo.phone'),
                label: 'Phone',
                controller: phoneController,
                keyboardType: TextInputType.phone,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _EmployeeInformationTextField(
                fieldKey: const ValueKey<String>(
                  'payroll.employeeInfo.dateHire',
                ),
                label: 'Date Hire',
                controller: dateHireController,
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _EmployeeInformationJobTypeField(
                value: jobType,
                jobTypes: jobTypes,
                onChanged: onJobTypeChanged,
              ),
            ),
            SizedBox(
              width: constraints.maxWidth,
              child: _EmployeeInformationTextField(
                fieldKey: const ValueKey<String>(
                  'payroll.employeeInfo.address',
                ),
                label: 'Address',
                controller: addressController,
                minLines: 2,
                maxLines: 3,
              ),
            ),
            if (showW4)
              SizedBox(
                width: constraints.maxWidth,
                child: _EmployeeInformationTextField(
                  fieldKey: const ValueKey<String>('payroll.employeeInfo.w4'),
                  label: 'W4',
                  controller: linkW4Controller,
                  keyboardType: TextInputType.url,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmployeeInformationTextField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  const _EmployeeInformationTextField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _PayrollTokens.detailLabel),
        const SizedBox(height: 8),
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          minLines: minLines,
          maxLines: maxLines,
          style: _PayrollTokens.detailValue,
          decoration: _PayrollTokens.inputDecoration,
        ),
      ],
    );
  }
}

class _EmployeeInformationJobTypeField extends StatelessWidget {
  final String value;
  final List<String> jobTypes;
  final ValueChanged<String?> onChanged;

  const _EmployeeInformationJobTypeField({
    required this.value,
    required this.jobTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Job Type', style: _PayrollTokens.detailLabel),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const ValueKey<String>('payroll.employeeInfo.jobType'),
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: _PayrollTokens.inputDecoration,
          items: <DropdownMenuItem<String>>[
            for (final String jobType in jobTypes)
              DropdownMenuItem<String>(value: jobType, child: Text(jobType)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _EmployeeDetailGrid extends StatelessWidget {
  final List<_EmployeeDetailData> details;

  const _EmployeeDetailGrid({required this.details});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool twoColumns = constraints.maxWidth >= 520;
        const double gap = 18;
        final double width = twoColumns
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: 22,
          children: <Widget>[
            for (final _EmployeeDetailData detail in details)
              SizedBox(
                width: width,
                child: _EmployeeDetailLine(
                  label: detail.label,
                  value: detail.value,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmployeeDetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _EmployeeDetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Text(label, style: _PayrollTokens.detailLabel),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            style: _PayrollTokens.detailValue,
          ),
        ),
      ],
    );
  }
}

class _EmployeeDetailData {
  final String label;
  final String value;

  const _EmployeeDetailData({required this.label, required this.value});
}

class _AddEmployeeDialog extends StatefulWidget {
  const _AddEmployeeDialog();

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  static const List<String> _jobTypes = <String>[
    'Hourly',
    'Salary',
    'Contractor',
    'Part Time',
    'Full Time',
  ];
  static const List<String> _payMethods = <String>[
    'Direct Deposit',
    'Check',
    'Cash',
    'Payroll Card',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateHireController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _linkW4Controller = TextEditingController();

  String? _jobType;
  String? _payMethod;

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthdayController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateHireController.dispose();
    _rateController.dispose();
    _linkW4Controller.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final DateTime today = _dateOnly(AppClock.now);
    await _pickDate(
      controller: _birthdayController,
      helpText: 'Choose birthday',
      initialDate: DateTime(today.year - 25, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
    );
  }

  Future<void> _pickDateHire() async {
    await _pickDate(
      controller: _dateHireController,
      helpText: 'Choose date hire',
      initialDate: _dateOnly(AppClock.now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required String helpText,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(controller.text) ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
    );
    if (picked == null || !mounted) return;

    setState(() => controller.text = _formatDate(picked));
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(
      context,
      PayrollEmployee(
        id: '',
        name: _fullNameController.text.trim(),
        rate: parseMoney(_rateController.text),
        birthday: _birthdayController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        dateHire: _dateHireController.text.trim(),
        jobType: _jobType ?? '',
        payMethod: _payMethod ?? '',
        linkW4: _linkW4Controller.text.trim(),
      ),
    );
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _requiredDropdown(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _requiredRate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (parseMoney(value) <= 0) return 'Enter a valid rate';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: _PayrollTokens.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_PayrollTokens.cardRadius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 860,
          maxHeight: screenSize.height - 48,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool stacked = constraints.maxWidth < 640;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 20, 12),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Add New Employee',
                          style: _PayrollTokens.dialogTitle,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey<String>(
                          'payroll.addEmployee.close',
                        ),
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: _PayrollTokens.textMuted,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                    child: Form(
                      key: _formKey,
                      child: _AddEmployeeFieldRows(
                        stacked: stacked,
                        rows: <List<Widget>>[
                          <Widget>[
                            _AddEmployeeTextField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.fullName',
                              ),
                              label: 'Full Name',
                              requiredField: true,
                              controller: _fullNameController,
                              hintText: 'Enter full name',
                              validator: _requiredText,
                              textInputAction: TextInputAction.next,
                            ),
                            _AddEmployeeDropdownField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.jobType',
                              ),
                              label: 'Job Type',
                              requiredField: true,
                              value: _jobType,
                              hintText: 'Select job type',
                              items: _jobTypes,
                              validator: _requiredDropdown,
                              onChanged: (String? value) =>
                                  setState(() => _jobType = value),
                            ),
                          ],
                          <Widget>[
                            _AddEmployeeDateField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.birthday',
                              ),
                              label: 'Birthday',
                              controller: _birthdayController,
                              onTap: _pickBirthday,
                              validator: _requiredText,
                            ),
                            _AddEmployeeTextField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.rate',
                              ),
                              label: 'Rate',
                              requiredField: true,
                              controller: _rateController,
                              hintText: 'Enter rate',
                              prefixText: r'$',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              validator: _requiredRate,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                          <Widget>[
                            _AddEmployeeTextField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.phone',
                              ),
                              label: 'Phone',
                              requiredField: true,
                              controller: _phoneController,
                              hintText: 'Enter phone number',
                              keyboardType: TextInputType.phone,
                              validator: _requiredText,
                              textInputAction: TextInputAction.next,
                            ),
                            _AddEmployeeDropdownField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.payMethod',
                              ),
                              label: 'Pay Method',
                              optional: true,
                              value: _payMethod,
                              hintText: 'Select pay method (optional)',
                              items: _payMethods,
                              onChanged: (String? value) =>
                                  setState(() => _payMethod = value),
                            ),
                          ],
                          <Widget>[
                            _AddEmployeeTextField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.address',
                              ),
                              label: 'Address',
                              requiredField: true,
                              controller: _addressController,
                              hintText: 'Enter address',
                              minLines: 3,
                              maxLines: 3,
                              validator: _requiredText,
                              textInputAction: TextInputAction.newline,
                            ),
                            _AddEmployeeTextField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.linkW4',
                              ),
                              label: 'Link W4',
                              optional: true,
                              controller: _linkW4Controller,
                              hintText: 'Enter link to W4 (optional)',
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                          <Widget>[
                            _AddEmployeeDateField(
                              fieldKey: const ValueKey<String>(
                                'payroll.addEmployee.dateHire',
                              ),
                              label: 'Date Hire',
                              controller: _dateHireController,
                              onTap: _pickDateHire,
                              validator: _requiredText,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: _PayrollTokens.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 22),
                  child: Align(
                    alignment: stacked
                        ? Alignment.center
                        : Alignment.centerRight,
                    child: SizedBox(
                      width: stacked ? double.infinity : 120,
                      height: 48,
                      child: FilledButton(
                        key: const ValueKey<String>('payroll.addEmployee.done'),
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
                        child: const Text('Done'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddEmployeeFieldRows extends StatelessWidget {
  final bool stacked;
  final List<List<Widget>> rows;

  const _AddEmployeeFieldRows({required this.stacked, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int index = 0; index < rows.length; index += 1) ...<Widget>[
          if (stacked)
            for (
              int fieldIndex = 0;
              fieldIndex < rows[index].length;
              fieldIndex += 1
            ) ...<Widget>[
              rows[index][fieldIndex],
              if (fieldIndex < rows[index].length - 1)
                const SizedBox(height: 18),
            ]
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: rows[index].first),
                const SizedBox(width: 24),
                Expanded(
                  child: rows[index].length > 1
                      ? rows[index][1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          if (index < rows.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _AddEmployeeTextField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final bool requiredField;
  final bool optional;
  final TextEditingController controller;
  final String hintText;
  final String? prefixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;

  const _AddEmployeeTextField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.hintText,
    this.requiredField = false,
    this.optional = false,
    this.prefixText,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return _AddEmployeeFieldFrame(
      label: label,
      requiredField: requiredField,
      optional: optional,
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        textInputAction: textInputAction,
        style: _PayrollTokens.inputText,
        decoration: _PayrollTokens.inputDecoration.copyWith(
          hintText: hintText,
          hintStyle: _PayrollTokens.inputHint,
          prefixText: prefixText == null ? null : '$prefixText  ',
          prefixStyle: _PayrollTokens.inputText,
        ),
      ),
    );
  }
}

class _AddEmployeeDateField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;
  final FormFieldValidator<String>? validator;

  const _AddEmployeeDateField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return _AddEmployeeFieldFrame(
      label: label,
      requiredField: true,
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        readOnly: true,
        onTap: onTap,
        validator: validator,
        style: _PayrollTokens.inputText,
        decoration: _PayrollTokens.inputDecoration.copyWith(
          hintText: 'MM/DD/YYYY',
          hintStyle: _PayrollTokens.inputHint,
          suffixIcon: IconButton(
            tooltip: 'Choose $label',
            onPressed: onTap,
            icon: const Icon(Icons.calendar_month_outlined),
            color: _PayrollTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

class _AddEmployeeDropdownField extends StatelessWidget {
  final Key fieldKey;
  final String label;
  final bool requiredField;
  final bool optional;
  final String? value;
  final String hintText;
  final List<String> items;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String?> onChanged;

  const _AddEmployeeDropdownField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.requiredField = false,
    this.optional = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return _AddEmployeeFieldFrame(
      label: label,
      requiredField: requiredField,
      optional: optional,
      child: DropdownButtonFormField<String>(
        key: fieldKey,
        initialValue: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down),
        decoration: _PayrollTokens.inputDecoration,
        hint: Text(hintText, style: _PayrollTokens.inputHint),
        validator: validator,
        items: <DropdownMenuItem<String>>[
          for (final String item in items)
            DropdownMenuItem<String>(value: item, child: Text(item)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _AddEmployeeFieldFrame extends StatelessWidget {
  final String label;
  final bool requiredField;
  final bool optional;
  final Widget child;

  const _AddEmployeeFieldFrame({
    required this.label,
    required this.child,
    this.requiredField = false,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AddEmployeeLabel(
          label: label,
          requiredField: requiredField,
          optional: optional,
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AddEmployeeLabel extends StatelessWidget {
  final String label;
  final bool requiredField;
  final bool optional;

  const _AddEmployeeLabel({
    required this.label,
    required this.requiredField,
    required this.optional,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: _PayrollTokens.dialogFieldLabel,
        children: <InlineSpan>[
          TextSpan(text: label),
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          if (optional)
            TextSpan(
              text: ' (optional)',
              style: _PayrollTokens.dialogOptionalLabel,
            ),
        ],
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

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 560;

        return Container(
          decoration: _PayrollTokens.panelDecoration,
          padding: EdgeInsets.all(narrow ? 16 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (narrow) ...<Widget>[
                _PayrollHeaderMetrics(
                  balance: state.balance,
                  totalPay: state.payPeriodTotalPay,
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: _PayrollTokens.divider),
                const SizedBox(height: 18),
                _ProcessDateField(
                  processDate: payroll.processDate,
                  onTap: onChooseProcessDays,
                ),
              ] else ...<Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _PayrollHeaderMetrics(
                        balance: state.balance,
                        totalPay: state.payPeriodTotalPay,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 80,
                      color: _PayrollTokens.divider,
                    ),
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
              ],
              const SizedBox(height: 18),
              const Divider(height: 1, color: _PayrollTokens.divider),
              const SizedBox(height: 18),
              _ResponsiveFieldPair(
                first: _DateInputTile(
                  label: 'PAY DATE',
                  value: _formatDate(payroll.payDate),
                  onTap: onPickPayDate,
                ),
                second: _ScheduleDropdown(
                  value: payroll.schedule,
                  onChanged: onScheduleChanged,
                ),
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
            ],
          ),
        );
      },
    );
  }
}

class _PayrollHeaderMetrics extends StatelessWidget {
  final double balance;
  final double totalPay;

  const _PayrollHeaderMetrics({required this.balance, required this.totalPay});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SummaryMetric(label: 'BALANCE', value: formatMoney(balance)),
              const SizedBox(height: 16),
              _SummaryMetric(label: 'TOTAL PAY', value: formatMoney(totalPay)),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _SummaryMetric(
                label: 'BALANCE',
                value: formatMoney(balance),
              ),
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 76, color: _PayrollTokens.divider),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryMetric(
                label: 'TOTAL PAY',
                value: formatMoney(totalPay),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 16),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: _PayrollTokens.balanceValue),
        ),
      ],
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
        _TappableField(
          value: _formatDate(processDate),
          icon: Icons.calendar_month_outlined,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _ResponsiveFieldPair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsiveFieldPair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            children: <Widget>[first, const SizedBox(height: 14), second],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: first),
            const SizedBox(width: 14),
            Container(width: 1, height: 70, color: _PayrollTokens.divider),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
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
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              Icon(icon, color: _PayrollTokens.textMuted, size: 25),
            ],
          ),
        ),
      ),
    );
  }
}

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

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime? _parseDate(String value) {
  final List<String> parts = value.split('/');
  if (parts.length != 3) return null;

  final int? month = int.tryParse(parts[0]);
  final int? day = int.tryParse(parts[1]);
  final int? year = int.tryParse(parts[2]);
  if (month == null || day == null || year == null) return null;

  return DateTime(year, month, day);
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
  static const Color tabSelected = Color(0xFF0B7CFF);
  static const Color textStrong = Color(0xFF111827);
  static const Color textMuted = Color(0xFF4B5563);
  static const Color border = Color(0xFFD8DEE8);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF57B82F);
  static const Color selectedRow = Color(0xFFEAF4FF);
  static const Color lockedFieldBackground = Color(0xFFF8FAFC);

  static const double cardRadius = 8;
  static const double controlRadius = 6;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 24);

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
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
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

  static InputDecoration get searchDecoration => InputDecoration(
    hintText: 'Search employees...',
    hintStyle: inputHint,
    prefixIcon: const Icon(Icons.search, color: textMuted),
    filled: true,
    fillColor: surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: tabSelected, width: 1.4),
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
  static const TextStyle sectionTitle = TextStyle(
    color: Colors.black,
    fontSize: 22,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle employeesTitle = TextStyle(
    color: textStrong,
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle cardTitle = TextStyle(
    color: textStrong,
    fontSize: 22,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle dialogTitle = TextStyle(
    color: textStrong,
    fontSize: 24,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle dialogFieldLabel = TextStyle(
    color: textStrong,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle dialogOptionalLabel = TextStyle(
    color: textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle listHeader = TextStyle(
    color: textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle fieldLabel = TextStyle(
    color: Color(0xFF4B5563),
    fontSize: 13,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle cardFieldLabel = TextStyle(
    color: Color(0xFF4B5563),
    fontSize: 14,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle balanceValue = TextStyle(
    color: Colors.black,
    fontSize: 28,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle inputText = TextStyle(
    color: textStrong,
    fontSize: 17,
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
  static const TextStyle employeeListName = TextStyle(
    color: textStrong,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle detailLabel = TextStyle(
    color: textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle detailValue = TextStyle(
    color: textStrong,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.35,
  );
  static const TextStyle inlineLabel = TextStyle(
    color: textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle cardMiniLabel = TextStyle(
    color: textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle employeeName = TextStyle(
    color: Colors.black,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const TextStyle rowTotal = TextStyle(
    color: Colors.black,
    fontSize: 26,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle footerTotal = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );
}
