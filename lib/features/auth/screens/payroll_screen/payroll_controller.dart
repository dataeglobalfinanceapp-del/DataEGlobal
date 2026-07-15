import 'package:flutter/foundation.dart';

import 'package:savetep/data/dto/save_employee_request.dart';
import 'package:savetep/data/repositories/employee_repository.dart';
import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/domain/services/employee_service.dart';
import 'package:savetep/services/liability_service.dart';

import 'payroll_models.dart';
import 'payroll_expense_service.dart';
import 'payroll_pay_date_validator.dart';
import 'payroll_reminder_service.dart';
import 'payroll_service.dart';

class PayrollViewState {
  final bool isLoading;
  final PayrollRecord payroll;
  final double balance;

  const PayrollViewState({
    required this.isLoading,
    required this.payroll,
    required this.balance,
  });

  factory PayrollViewState.initial() {
    return PayrollViewState(
      isLoading: true,
      payroll: PayrollRecord.draft(id: 'payroll-loading'),
      balance: 0,
    );
  }
}

class PayrollController extends ChangeNotifier {
  bool _isLoading = true;
  bool _isDisposed = false;

  final EmployeeService _employeeService;
  PayrollRecord _payroll = PayrollRecord.draft(id: 'payroll-loading');
  List<DepositRecord> _deposits = const <DepositRecord>[];
  List<ExpenseRecord> _expenses = const <ExpenseRecord>[];
  PayrollViewState _state = PayrollViewState.initial();

  PayrollController({EmployeeService? employeeService})
    : _employeeService = employeeService ?? EmployeeService();

  PayrollViewState get state => _state;

  Future<void> load() async {
    _setLoading(true);

    final payroll = await PayrollService.loadCurrentPayroll();
    final employeeRecords = await _employeeService.loadEmployees();
    final deposits = await LiabilityService.loadDeposits();
    final expenses = await LiabilityService.loadExpenses();
    if (_isDisposed) return;

    _payroll = payroll.copyWith(
      employees: _payrollEmployeesFromRecords(payroll, employeeRecords),
    );
    _deposits = List<DepositRecord>.unmodifiable(deposits);
    _expenses = List<ExpenseRecord>.unmodifiable(expenses);
    await PayrollReminderService.syncEmployees(_payroll.employees);
    if (_isDisposed) return;

    _isLoading = false;
    _rebuildState();
    _notify();
  }

  void setPayDate(DateTime payDate) {
    final DateTime nextPayDate = PayrollPayDateValidator.normalizePayDate(
      payDate,
    );
    if (_isSameDate(_payroll.payDate, nextPayDate)) return;

    _payroll = _payroll.copyWith(payDate: nextPayDate);
    _rebuildState();
    _notify();
  }

  Future<void> addEmployeeRecord(PayrollEmployee employee) async {
    final EmployeeRecord savedEmployee = await _employeeService.saveEmployee(
      _saveEmployeeRequestFrom(employee),
    );
    if (_isDisposed) return;

    final employees = <PayrollEmployee>[
      ..._payroll.employees,
      _payrollEmployeeFromRecord(savedEmployee, existing: employee),
    ];
    _payroll = _payroll.copyWith(employees: employees);
    _rebuildState();
    _notify();
  }

  Future<void> removeEmployee(String id) async {
    if (_payroll.employees.length <= 1) return;

    await _employeeService.deleteEmployee(id);
    if (_isDisposed) return;

    final employees = _payroll.employees
        .where((PayrollEmployee employee) => employee.id != id)
        .toList(growable: false);
    if (employees.length == _payroll.employees.length) return;

    _payroll = _payroll.copyWith(employees: employees);
    _rebuildState();
    _notify();
  }

  Future<void> updateEmployee(
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
    String? payMethod,
    String? linkW4,
    PayrollAction? payrollAction,
    bool? confirmPayroll,
  }) async {
    final bool shouldConfirmPayroll = confirmPayroll == true;
    final bool payrollFieldsChanged =
        rate != null ||
        regularHours != null ||
        overtimeHours != null ||
        commission != null ||
        tips != null;
    final bool payrollStateChanged =
        payrollFieldsChanged || payrollAction != null || shouldConfirmPayroll;
    final int employeeIndex = _payroll.employees.indexWhere(
      (PayrollEmployee employee) => employee.id == id,
    );
    if (employeeIndex == -1) return;

    final PayrollEmployee employee = _payroll.employees[employeeIndex];
    final PayrollAction nextPayrollAction =
        payrollAction ??
        (payrollFieldsChanged ? PayrollAction.change : employee.payrollAction);
    final PayrollEmployee updatedEmployee = employee.copyWith(
      name: name,
      rate: rate,
      regularHours: regularHours,
      overtimeHours: overtimeHours,
      commission: commission,
      tips: tips,
      birthday: birthday,
      phone: phone,
      address: address,
      dateHire: dateHire,
      jobType: jobType,
      payMethod: payMethod,
      linkW4: linkW4,
      payrollAction: nextPayrollAction,
      isPayrollConfirmed: shouldConfirmPayroll
          ? true
          : payrollStateChanged
          ? false
          : employee.isPayrollConfirmed,
    );
    final List<PayrollEmployee> employees = List<PayrollEmployee>.of(
      _payroll.employees,
    );
    employees[employeeIndex] = updatedEmployee;

    _payroll = _payroll.copyWith(employees: employees);
    _rebuildState();
    _notify();
    await _employeeService.saveEmployee(
      _saveEmployeeRequestFrom(updatedEmployee),
    );
    if (shouldConfirmPayroll) {
      await PayrollExpenseService.syncConfirmedEmployee(updatedEmployee);
    }
    if (payrollStateChanged && _payroll.allEmployeesConfirmed) {
      await _saveConfirmedPayroll();
    } else if (payrollStateChanged) {
      await _saveDraftPayroll();
    }
  }

  Future<void> updateEmployeePayrollSetting(
    String id,
    EmployeePayrollSetting setting,
  ) async {
    final int employeeIndex = _payroll.employees.indexWhere(
      (PayrollEmployee employee) => employee.id == id,
    );
    if (employeeIndex == -1) return;

    final PayrollEmployee employee = _payroll.employees[employeeIndex];
    if (employee.payrollSetting == setting) return;

    final PayrollEmployee updatedEmployee = employee.copyWith(
      payrollSetting: setting,
    );
    final List<PayrollEmployee> employees = List<PayrollEmployee>.of(
      _payroll.employees,
    );
    employees[employeeIndex] = updatedEmployee;

    _payroll = _payroll.copyWith(employees: employees);
    _rebuildState();
    _notify();
    await _employeeService.saveEmployee(
      _saveEmployeeRequestFrom(updatedEmployee),
    );
    await PayrollReminderService.syncEmployee(updatedEmployee);
    if (updatedEmployee.isPayrollConfirmed) {
      await PayrollExpenseService.syncConfirmedEmployee(updatedEmployee);
      final List<ExpenseRecord> expenses =
          await LiabilityService.loadExpenses();
      if (_isDisposed) return;

      _expenses = List<ExpenseRecord>.unmodifiable(expenses);
      _rebuildState();
      _notify();
    }
  }

  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;
    _isLoading = isLoading;
    _rebuildState();
    _notify();
  }

  void _rebuildState() {
    final DateTime payDate = _dateOnly(_payroll.payDate);
    final double totalDeposits = _deposits
        .where(
          (DepositRecord record) =>
              !_dateOnly(record.transactionDate).isAfter(payDate),
        )
        .fold<double>(
          0,
          (double total, DepositRecord record) => total + record.totalAmount,
        );
    final double totalExpensesBeforePayroll = _expenses
        .where((ExpenseRecord record) {
          if (record.id == _payroll.syncedExpenseId) return false;
          return !_dateOnly(record.transactionDate).isAfter(payDate);
        })
        .fold<double>(
          0,
          (double total, ExpenseRecord record) => total + record.totalAmount,
        );
    final double projectedPayrollExpense = _payroll.employees
        .where((PayrollEmployee employee) => !employee.isPayrollConfirmed)
        .fold<double>(
          0,
          (double total, PayrollEmployee employee) => total + employee.totalPay,
        );
    final double totalExpenses =
        totalExpensesBeforePayroll + projectedPayrollExpense;

    _state = PayrollViewState(
      isLoading: _isLoading,
      payroll: _payroll,
      balance: totalDeposits - totalExpenses,
    );
  }

  void _notify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  Future<void> _saveConfirmedPayroll() async {
    final PayrollRecord savedPayroll = await PayrollService.savePayroll(
      _payroll,
    );
    final List<DepositRecord> deposits = await LiabilityService.loadDeposits();
    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();
    if (_isDisposed) return;

    _payroll = savedPayroll;
    _deposits = List<DepositRecord>.unmodifiable(deposits);
    _expenses = List<ExpenseRecord>.unmodifiable(expenses);
    _rebuildState();
    _notify();
  }

  Future<void> _saveDraftPayroll() async {
    final PayrollRecord savedPayroll = await PayrollService.savePayrollDraft(
      _payroll,
    );
    final List<DepositRecord> deposits = await LiabilityService.loadDeposits();
    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();
    if (_isDisposed) return;

    _payroll = savedPayroll;
    _deposits = List<DepositRecord>.unmodifiable(deposits);
    _expenses = List<ExpenseRecord>.unmodifiable(expenses);
    _rebuildState();
    _notify();
  }

  List<PayrollEmployee> _payrollEmployeesFromRecords(
    PayrollRecord payroll,
    List<EmployeeRecord> records,
  ) {
    return records
        .map(
          (EmployeeRecord record) => _payrollEmployeeFromRecord(
            record,
            existing: _employeeById(payroll.employees, record.id),
          ),
        )
        .toList(growable: false);
  }

  PayrollEmployee _payrollEmployeeFromRecord(
    EmployeeRecord record, {
    PayrollEmployee? existing,
  }) {
    final EmployeePayrollSetting? payrollSetting =
        record.payrollSetting ?? existing?.payrollSetting;

    return PayrollEmployee(
      id: record.id,
      name: record.fullName.trim().isEmpty
          ? existing?.name ?? ''
          : record.fullName,
      rate: existing?.rate ?? record.rate,
      regularHours: existing?.regularHours ?? 0,
      overtimeHours: existing?.overtimeHours ?? 0,
      commission: existing?.commission ?? 0,
      tips: existing?.tips ?? 0,
      birthday: record.birthday,
      phone: record.phone,
      address: record.address,
      jobType: record.jobType,
      dateHire: record.dateHire,
      payMethod: record.payMethod,
      linkW4: record.linkW4,
      payrollSetting: payrollSetting,
      payrollAction: existing?.payrollAction ?? PayrollAction.same,
      isPayrollConfirmed: existing?.isPayrollConfirmed ?? false,
    );
  }

  PayrollEmployee? _employeeById(List<PayrollEmployee> employees, String id) {
    for (final PayrollEmployee employee in employees) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  SaveEmployeeRequest _saveEmployeeRequestFrom(PayrollEmployee employee) {
    return SaveEmployeeRequest(
      id: employee.id,
      fullName: employee.name,
      birthday: employee.birthday,
      phone: employee.phone,
      address: employee.address,
      dateHire: employee.dateHire,
      jobType: employee.jobType,
      rate: employee.rate,
      payMethod: employee.payMethod,
      linkW4: employee.linkW4,
      payrollSetting: employee.payrollSetting,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
