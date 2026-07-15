import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:savetep/domain/models/temporary_employee_document.dart';
import 'package:savetep/domain/services/employee_document_capture_service.dart';
import 'package:savetep/domain/services/employee_document_email_service.dart';
import 'package:savetep/domain/services/employee_document_email_service_factory.dart';
import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/money_formatter.dart';

import 'employee_form_data.dart';
import 'payroll_controller.dart';
import 'payroll_models.dart';
import 'payroll_period_calculator.dart';
import 'payroll_report_email_service.dart';
import 'employee_create_draft.dart';

part 'payroll/tabs.dart';
part 'payroll/employees_tab.dart';
part 'payroll/dialogs.dart';
part 'payroll/settings_screen.dart';
part 'payroll/setup_card.dart';
part 'payroll/employee_payroll_list.dart';
part 'payroll/helpers.dart';
part 'payroll/tokens.dart';

typedef _EmployeeChanged =
    Future<void> Function(
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
      PayrollAction? payrollAction,
      bool? confirmPayroll,
    });

enum _PayrollTab {
  payroll('Payroll', Icons.people_alt_outlined),
  employees('Employees', Icons.groups_2_outlined);

  final String label;
  final IconData icon;

  const _PayrollTab(this.label, this.icon);
}

class PayrollScreen extends StatefulWidget {
  final EmployeeDocumentEmailService? employeeDocumentEmailService;
  final EmployeeDocumentCaptureService? employeeDocumentCaptureService;
  final PayrollEmailSender? payrollEmailSender;

  const PayrollScreen({
    super.key,
    this.employeeDocumentEmailService,
    this.employeeDocumentCaptureService,
    this.payrollEmailSender,
  });

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  late final PayrollController _controller;
  late final EmployeeDocumentEmailService _employeeDocumentEmailService;
  late final EmployeeDocumentCaptureService _employeeDocumentCaptureService;
  late final PayrollEmailSender _payrollEmailSender;
  _PayrollTab _selectedTab = _PayrollTab.payroll;

  @override
  void initState() {
    super.initState();
    _controller = PayrollController()..load();
    _employeeDocumentEmailService =
        widget.employeeDocumentEmailService ??
        createEmployeeDocumentEmailService();
    _employeeDocumentCaptureService =
        widget.employeeDocumentCaptureService ??
        ImagePickerEmployeeDocumentCaptureService();
    _payrollEmailSender =
        widget.payrollEmailSender ?? const MockPayrollEmailSender();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAddEmployeeDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => _AddEmployeeDialog(
        emailService: _employeeDocumentEmailService,
        captureService: _employeeDocumentCaptureService,
        onEmployeeCreated: _controller.addEmployeeRecord,
      ),
    );
  }

  Future<void> _openPayrollSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            _PayrollSettingsScreen(controller: _controller),
      ),
    );
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
            key: const ValueKey<String>('payroll.settings.open'),
            tooltip: 'Payroll settings',
            onPressed: _openPayrollSettings,
            icon: const Icon(Icons.settings_outlined),
            color: _PayrollTokens.textMuted,
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
                  onEmployeeChanged: _controller.updateEmployee,
                  payrollEmailSender: _payrollEmailSender,
                )
              else
                _EmployeesTabContentConsumer(
                  controller: _controller,
                  onCreateEmployee: _openAddEmployeeDialog,
                  onRemoveEmployee: _controller.removeEmployee,
                  onEmployeeChanged: _controller.updateEmployee,
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
