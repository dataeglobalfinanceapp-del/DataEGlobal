import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/money_formatter.dart';

import 'payroll_controller.dart';
import 'payroll_models.dart';

part 'payroll/tabs.dart';
part 'payroll/employees_tab.dart';
part 'payroll/dialogs.dart';
part 'payroll/setup_card.dart';
part 'payroll/employee_payroll_list.dart';
part 'payroll/helpers.dart';
part 'payroll/tokens.dart';

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
