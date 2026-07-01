import 'package:flutter/foundation.dart';

import 'package:savetep/data/dto/save_employee_request.dart';
import 'package:savetep/data/repositories/employee_repository.dart';
import 'package:savetep/domain/services/employee_service.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/recurrence_schedule.dart';

import 'payroll_models.dart';
import 'payroll_service.dart';

class PayrollViewState {
  final bool isLoading;
  final PayrollRecord payroll;
  final double balance;
  final double payPeriodTotalPay;

  const PayrollViewState({
    required this.isLoading,
    required this.payroll,
    required this.balance,
    required this.payPeriodTotalPay,
  });

  factory PayrollViewState.initial() {
    return PayrollViewState(
      isLoading: true,
      payroll: PayrollRecord.draft(id: 'payroll-loading'),
      balance: 0,
      payPeriodTotalPay: 0,
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
    final employeeRecords = await _loadEmployeeRecordsFor(payroll);
    final deposits = await LiabilityService.loadDeposits();
    final expenses = await LiabilityService.loadExpenses();
    if (_isDisposed) return;

    _payroll = payroll.copyWith(
      employees: _payrollEmployeesFromRecords(payroll, employeeRecords),
    );
    _deposits = List<DepositRecord>.unmodifiable(deposits);
    _expenses = List<ExpenseRecord>.unmodifiable(expenses);
    _isLoading = false;
    _rebuildState();
    _notify();
  }

  void setPayDate(DateTime payDate) {
    final DateTime nextPayDate = RecurrenceSchedule.dateOnly(payDate);
    if (RecurrenceSchedule.isSameDate(_payroll.payDate, nextPayDate)) return;

    _payroll = _payroll.copyWith(payDate: nextPayDate);
    _rebuildState();
    _notify();
  }

  void setSchedule(PayrollSchedule schedule) {
    if (_payroll.schedule == schedule) return;

    _payroll = _payroll.copyWith(schedule: schedule);
    _rebuildState();
    _notify();
  }

  void setProcessDaysBefore(int days) {
    final int nextDays = days.clamp(1, 31).toInt();
    if (_payroll.processDaysBefore == nextDays) return;

    _payroll = _payroll.copyWith(processDaysBefore: nextDays);
    _rebuildState();
    _notify();
  }

  Future<void> addEmployee() async {
    final EmployeeRecord savedEmployee = await _employeeService.saveEmployee(
      _saveEmployeeRequestFrom(
        const PayrollEmployee(id: '', name: 'New Employee'),
      ),
    );
    if (_isDisposed) return;

    final employees = <PayrollEmployee>[
      ..._payroll.employees,
      _payrollEmployeeFromRecord(savedEmployee),
    ];
    _payroll = _payroll.copyWith(employees: employees);
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
  }) async {
    final bool shouldSyncPayrollExpense =
        rate != null ||
        regularHours != null ||
        overtimeHours != null ||
        commission != null ||
        tips != null;
    PayrollEmployee? updatedEmployee;
    final employees = _payroll.employees
        .map((PayrollEmployee employee) {
          if (employee.id != id) return employee;
          updatedEmployee = employee.copyWith(
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
          );
          return updatedEmployee!;
        })
        .toList(growable: false);
    if (updatedEmployee == null) return;

    _payroll = _payroll.copyWith(employees: employees);
    _rebuildState();
    _notify();
    await _employeeService.saveEmployee(
      _saveEmployeeRequestFrom(updatedEmployee!),
    );
    if (shouldSyncPayrollExpense) {
      await _saveConfirmedPayroll();
    }
  }

  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;
    _isLoading = isLoading;
    _rebuildState();
    _notify();
  }

  void _rebuildState() {
    final DateTime payDate = RecurrenceSchedule.dateOnly(_payroll.payDate);
    final DateTime payPeriodStart = RecurrenceSchedule.dateOnly(
      _payroll.payPeriodStart,
    );
    final DateTime payPeriodEnd = RecurrenceSchedule.dateOnly(
      _payroll.payPeriodEnd,
    );
    final double totalDeposits = _deposits
        .where(
          (DepositRecord record) => !RecurrenceSchedule.dateOnly(
            record.transactionDate,
          ).isAfter(payDate),
        )
        .fold<double>(
          0,
          (double total, DepositRecord record) => total + record.totalAmount,
        );
    final double totalExpensesBeforePayroll = _expenses
        .where((ExpenseRecord record) {
          if (record.id == _payroll.syncedExpenseId) return false;
          return !RecurrenceSchedule.dateOnly(
            record.transactionDate,
          ).isAfter(payDate);
        })
        .fold<double>(
          0,
          (double total, ExpenseRecord record) => total + record.totalAmount,
        );
    final double projectedPayrollExpense = _payroll.totalPay > 0
        ? _payroll.totalPay
        : 0;
    final double totalExpenses =
        totalExpensesBeforePayroll + projectedPayrollExpense;
    final double payPeriodTotalPay = _payPeriodPayrollExpenseTotal(
      payPeriodStart: payPeriodStart,
      payPeriodEnd: payPeriodEnd,
      projectedPayrollExpense: projectedPayrollExpense,
    );

    _state = PayrollViewState(
      isLoading: _isLoading,
      payroll: _payroll,
      balance: totalDeposits - totalExpenses,
      payPeriodTotalPay: payPeriodTotalPay,
    );
  }

  double _payPeriodPayrollExpenseTotal({
    required DateTime payPeriodStart,
    required DateTime payPeriodEnd,
    required double projectedPayrollExpense,
  }) {
    bool payDateIsInSelectedPeriod(DateTime payDate) {
      final DateTime normalizedPayDate = RecurrenceSchedule.dateOnly(payDate);
      late final DateTime expensePeriodStart;
      late final DateTime expensePeriodEnd;

      if (_payroll.schedule == PayrollSchedule.monthly) {
        final DateTime previousMonth = DateTime(
          normalizedPayDate.year,
          normalizedPayDate.month - 1,
        );
        expensePeriodStart = DateTime(previousMonth.year, previousMonth.month);
        expensePeriodEnd = DateTime(
          normalizedPayDate.year,
          normalizedPayDate.month,
          0,
        );
      } else {
        expensePeriodEnd = normalizedPayDate.subtract(const Duration(days: 6));
        expensePeriodStart = expensePeriodEnd.subtract(
          const Duration(days: 13),
        );
      }

      return RecurrenceSchedule.isSameDate(
            expensePeriodStart,
            payPeriodStart,
          ) &&
          RecurrenceSchedule.isSameDate(expensePeriodEnd, payPeriodEnd);
    }

    final double savedPayrollExpenses = _expenses
        .where((ExpenseRecord record) {
          if (record.category != 'Payroll') return false;
          if (record.id == _payroll.syncedExpenseId &&
              projectedPayrollExpense > 0) {
            return false;
          }

          final DateTime transactionDate = RecurrenceSchedule.dateOnly(
            record.transactionDate,
          );
          return payDateIsInSelectedPeriod(transactionDate);
        })
        .fold<double>(
          0,
          (double total, ExpenseRecord record) => total + record.totalAmount,
        );

    return _roundMoney(savedPayrollExpenses + projectedPayrollExpense);
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

  Future<List<EmployeeRecord>> _loadEmployeeRecordsFor(
    PayrollRecord payroll,
  ) async {
    final List<EmployeeRecord> employeeRecords = await _employeeService
        .loadEmployees();
    if (employeeRecords.isNotEmpty) return employeeRecords;

    final List<EmployeeRecord> seededEmployees = <EmployeeRecord>[];
    for (final PayrollEmployee employee in payroll.employees) {
      seededEmployees.add(
        await _employeeService.saveEmployee(_saveEmployeeRequestFrom(employee)),
      );
    }
    return seededEmployees;
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
    return PayrollEmployee(
      id: record.id,
      name: record.fullName.trim().isEmpty
          ? existing?.name ?? ''
          : record.fullName,
      rate: record.rate > 0 ? record.rate : existing?.rate ?? 0,
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
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

double _roundMoney(double value) => (value * 100).roundToDouble() / 100;
