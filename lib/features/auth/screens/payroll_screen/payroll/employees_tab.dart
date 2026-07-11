part of '../payroll_screen.dart';

class _EmployeesManagementView extends StatefulWidget {
  final PayrollViewState state;
  final Future<void> Function() onCreateEmployee;
  final ValueChanged<String> onRemoveEmployee;
  final _EmployeeChanged onEmployeeChanged;

  const _EmployeesManagementView({
    required this.state,
    required this.onCreateEmployee,
    required this.onRemoveEmployee,
    required this.onEmployeeChanged,
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

  Future<void> _createEmployee() async {
    await widget.onCreateEmployee();
    if (!mounted) return;
    _syncSelectedEmployee();
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
            _EmployeesHeader(onCreateEmployee: _createEmployee),
            const SizedBox(height: 18),
            listCard,
          ],
        );
      },
    );
  }
}

class _EmployeesHeader extends StatelessWidget {
  final VoidCallback onCreateEmployee;

  const _EmployeesHeader({required this.onCreateEmployee});

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
          onPressed: onCreateEmployee,
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
