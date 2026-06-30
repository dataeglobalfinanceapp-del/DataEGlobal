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

    _controller.addEmployeeRecord(employee);
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
          final PayrollViewState state = _controller.state;
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              padding: _PayrollTokens.pagePadding,
              children: <Widget>[
                _PayrollTabCard(
                  selectedTab: _selectedTab,
                  onChanged: _selectTab,
                ),
                const SizedBox(height: 16),
                if (_selectedTab == _PayrollTab.payroll)
                  _PayrollProcessingView(
                    state: state,
                    onPickPayDate: _pickPayDate,
                    onChooseProcessDays: _chooseProcessDays,
                    onScheduleChanged: _controller.setSchedule,
                    onAddEmployee: _controller.addEmployee,
                    onRemoveEmployee: _controller.removeEmployee,
                    onEmployeeChanged: _controller.updateEmployee,
                    onSavePayroll: _savePayroll,
                  )
                else
                  _EmployeesManagementView(
                    state: state,
                    onAddEmployee: _openAddEmployeeDialog,
                    onRemoveEmployee: _controller.removeEmployee,
                    onEmployeeChanged: _controller.updateEmployee,
                    onSavePayroll: _savePayroll,
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
  final PayrollViewState state;
  final VoidCallback onPickPayDate;
  final VoidCallback onChooseProcessDays;
  final ValueChanged<PayrollSchedule> onScheduleChanged;
  final VoidCallback onAddEmployee;
  final ValueChanged<String> onRemoveEmployee;
  final _EmployeeChanged onEmployeeChanged;
  final VoidCallback onSavePayroll;

  const _PayrollProcessingView({
    required this.state,
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
        _PayrollSetupCard(
          state: state,
          onPickPayDate: onPickPayDate,
          onChooseProcessDays: onChooseProcessDays,
          onScheduleChanged: onScheduleChanged,
        ),
        const SizedBox(height: 18),
        _EmployeePayrollList(
          state: state,
          onAddEmployee: onAddEmployee,
          onRemoveEmployee: onRemoveEmployee,
          onEmployeeChanged: onEmployeeChanged,
        ),
        const SizedBox(height: 16),
        _SavePayrollButton(
          isSaving: state.isSaving,
          onPressed: state.isSaving ? null : onSavePayroll,
        ),
      ],
    );
  }
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
    final PayrollEmployee? selectedEmployee = employees
        .cast<PayrollEmployee?>()
        .firstWhere(
          (PayrollEmployee? employee) => employee?.id == _selectedEmployeeId,
          orElse: () => employees.isEmpty ? null : employees.first,
        );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 760;
        final Widget listCard = _EmployeeListCard(
          employees: filteredEmployees,
          selectedEmployeeId: selectedEmployee?.id,
          searchController: _searchController,
          totalEmployeeCount: employees.length,
          onSelectEmployee: _selectEmployee,
        );
        final Widget informationCard = _EmployeeInformationCard(
          employee: selectedEmployee,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _EmployeesHeader(onAddEmployee: _addEmployee),
            const SizedBox(height: 18),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 5, child: listCard),
                  const SizedBox(width: 20),
                  Expanded(flex: 7, child: informationCard),
                ],
              )
            else ...<Widget>[
              listCard,
              const SizedBox(height: 14),
              informationCard,
            ],
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

class _EmployeeInformationCard extends StatelessWidget {
  final PayrollEmployee? employee;

  const _EmployeeInformationCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    final PayrollEmployee? selected = employee;

    return Container(
      decoration: _PayrollTokens.panelDecoration,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: selected == null
          ? const SizedBox(
              height: 260,
              child: Center(
                child: Text(
                  'Select an employee.',
                  style: _PayrollTokens.helperText,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Employee Information',
                        style: _PayrollTokens.cardTitle,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit employee',
                      onPressed: () {},
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
                  ],
                ),
                const SizedBox(height: 24),
                _EmployeeDetailGrid(
                  details: <_EmployeeDetailData>[
                    _EmployeeDetailData(
                      label: 'Full Name',
                      value: selected.name,
                    ),
                    _EmployeeDetailData(
                      label: 'Birthday',
                      value: selected.birthday,
                    ),
                    _EmployeeDetailData(label: 'Phone', value: selected.phone),
                    _EmployeeDetailData(
                      label: 'Address',
                      value: selected.address,
                    ),
                    _EmployeeDetailData(
                      label: 'Job Type',
                      value: selected.jobType,
                    ),
                  ],
                ),
              ],
            ),
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
                _SummaryMetric(
                  label: 'BALANCE',
                  value: formatMoney(state.balance),
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
                      child: _SummaryMetric(
                        label: 'BALANCE',
                        value: formatMoney(state.balance),
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
              const SizedBox(height: 14),
              _MoneySyncStrip(
                totalPay: payroll.totalPay,
                totalDeposits: state.totalDeposits,
                totalExpenses: state.totalExpenses,
              ),
            ],
          ),
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
    final List<_MoneyMetricData> metrics = <_MoneyMetricData>[
      _MoneyMetricData(label: 'Total Pay', value: totalPay),
      _MoneyMetricData(label: 'Total Deposit', value: totalDeposits),
      _MoneyMetricData(label: 'Total Expense', value: totalExpenses),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gap = constraints.maxWidth < 360 ? 8 : 12;
        final int columns = constraints.maxWidth >= 480 ? 3 : 2;
        final double itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _PayrollTokens.syncBackground,
            borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
            border: Border.all(color: _PayrollTokens.border),
          ),
          child: Wrap(
            spacing: gap,
            runSpacing: 10,
            children: <Widget>[
              for (final _MoneyMetricData metric in metrics)
                SizedBox(
                  width: itemWidth,
                  child: _InlineMoneyMetric(
                    label: metric.label,
                    value: metric.value,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MoneyMetricData {
  final String label;
  final double value;

  const _MoneyMetricData({required this.label, required this.value});
}

class _InlineMoneyMetric extends StatelessWidget {
  final String label;
  final double value;

  const _InlineMoneyMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
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
  void didUpdateWidget(covariant _PayrollEmployeeCard oldWidget) {
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
      decoration: _PayrollTokens.panelDecoration,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: _SelectedEmployeeMark(),
              ),
              const SizedBox(width: 12),
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
                  onChanged: (String value) => widget.onChanged(name: value),
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
                onChanged: (double value) => widget.onChanged(rate: value),
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'regularHours',
                label: 'REG HRS',
                controller: _regularHoursController,
                hintText: 'Enter',
                onChanged: (double value) =>
                    widget.onChanged(regularHours: value),
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'overtimeHours',
                label: 'OT HRS',
                controller: _overtimeHoursController,
                hintText: 'Enter',
                onChanged: (double value) =>
                    widget.onChanged(overtimeHours: value),
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'commission',
                label: 'COMM',
                controller: _commissionController,
                hintText: 'Enter',
                onChanged: (double value) =>
                    widget.onChanged(commission: value),
              ),
              _PayrollAmountField(
                index: widget.index,
                field: 'tips',
                label: 'TIPS',
                controller: _tipsController,
                hintText: 'Enter',
                onChanged: (double value) => widget.onChanged(tips: value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Icon(
            Icons.badge_outlined,
            color: _PayrollTokens.textMuted,
            size: 21,
          ),
        ],
      ),
    );
  }
}

class _SelectedEmployeeMark extends StatelessWidget {
  const _SelectedEmployeeMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: _PayrollTokens.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _PayrollTokens.border),
      ),
      child: const Icon(Icons.check, color: _PayrollTokens.success, size: 24),
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
          >= 680 => 5,
          >= 500 => 3,
          >= 300 => 2,
          _ => 1,
        };
        const double gap = 10;
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

class _PayrollAmountField extends StatelessWidget {
  final int index;
  final String field;
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<double> onChanged;

  const _PayrollAmountField({
    required this.index,
    required this.field,
    required this.label,
    required this.controller,
    required this.onChanged,
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
              enabledBorder: _PayrollTokens.cellBorder,
              focusedBorder: _PayrollTokens.focusedCellBorder,
              border: _PayrollTokens.cellBorder,
            ),
            onChanged: (String value) => onChanged(parseMoney(value)),
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
  static const Color syncBackground = Color(0xFFF8FAFC);
  static const Color textStrong = Color(0xFF111827);
  static const Color textMuted = Color(0xFF4B5563);
  static const Color border = Color(0xFFD8DEE8);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF57B82F);
  static const Color selectedRow = Color(0xFFEAF4FF);

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
    fontSize: 12,
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
  static const TextStyle inlineValue = TextStyle(
    color: textStrong,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle cardMiniLabel = TextStyle(
    color: textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle employeeName = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const TextStyle rowTotal = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle footerTotal = TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );
}
