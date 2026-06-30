import 'package:flutter/foundation.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/recurrence_schedule.dart';

import 'payroll_models.dart';
import 'payroll_service.dart';

class PayrollViewState {
  final bool isLoading;
  final bool isSaving;
  final PayrollRecord payroll;
  final double balance;
  final double payPeriodTotalPay;

  const PayrollViewState({
    required this.isLoading,
    required this.isSaving,
    required this.payroll,
    required this.balance,
    required this.payPeriodTotalPay,
  });

  factory PayrollViewState.initial() {
    return PayrollViewState(
      isLoading: true,
      isSaving: false,
      payroll: PayrollRecord.draft(id: 'payroll-loading'),
      balance: 0,
      payPeriodTotalPay: 0,
    );
  }
}

class PayrollController extends ChangeNotifier {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDisposed = false;
  int _employeeIdCounter = 0;

  PayrollRecord _payroll = PayrollRecord.draft(id: 'payroll-loading');
  List<DepositRecord> _deposits = const <DepositRecord>[];
  List<ExpenseRecord> _expenses = const <ExpenseRecord>[];
  PayrollViewState _state = PayrollViewState.initial();

  PayrollViewState get state => _state;

  Future<void> load() async {
    _setLoading(true);

    final payroll = await PayrollService.loadCurrentPayroll();
    final deposits = await LiabilityService.loadDeposits();
    final expenses = await LiabilityService.loadExpenses();
    if (_isDisposed) return;

    _payroll = payroll;
    _deposits = List<DepositRecord>.unmodifiable(deposits);
    _expenses = List<ExpenseRecord>.unmodifiable(expenses);
    _isLoading = false;
    _rebuildState();
    _notify();
  }

  Future<bool> save() async {
    _setSaving(true);
    try {
      _payroll = await PayrollService.savePayroll(_payroll);
      _deposits = List<DepositRecord>.unmodifiable(
        await LiabilityService.loadDeposits(),
      );
      _expenses = List<ExpenseRecord>.unmodifiable(
        await LiabilityService.loadExpenses(),
      );
      _rebuildState();
      _notify();
      return true;
    } finally {
      _setSaving(false);
    }
  }

  void setPayDate(DateTime payDate) {
    _payroll = _payroll.copyWith(payDate: RecurrenceSchedule.dateOnly(payDate));
    _rebuildState();
    _notify();
  }

  void setSchedule(PayrollSchedule schedule) {
    _payroll = _payroll.copyWith(schedule: schedule);
    _rebuildState();
    _notify();
  }

  void setProcessDaysBefore(int days) {
    _payroll = _payroll.copyWith(processDaysBefore: days);
    _rebuildState();
    _notify();
  }

  void addEmployee() {
    final employees = <PayrollEmployee>[
      ..._payroll.employees,
      PayrollEmployee(id: _newEmployeeId(), name: 'New Employee'),
    ];
    _payroll = _payroll.copyWith(employees: employees);
    _rebuildState();
    _notify();
  }

  void addEmployeeRecord(PayrollEmployee employee) {
    final PayrollEmployee savedEmployee = employee.id.trim().isEmpty
        ? employee.copyWith(id: _newEmployeeId())
        : employee;
    final employees = <PayrollEmployee>[..._payroll.employees, savedEmployee];
    _payroll = _payroll.copyWith(employees: employees);
    _rebuildState();
    _notify();
  }

  void removeEmployee(String id) {
    if (_payroll.employees.length <= 1) return;

    final employees = _payroll.employees
        .where((PayrollEmployee employee) => employee.id != id)
        .toList(growable: false);
    if (employees.length == _payroll.employees.length) return;

    _payroll = _payroll.copyWith(employees: employees);
    _rebuildState();
    _notify();
  }

  void updateEmployee(
    String id, {
    String? name,
    double? rate,
    double? regularHours,
    double? overtimeHours,
    double? commission,
    double? tips,
  }) {
    final employees = _payroll.employees
        .map((PayrollEmployee employee) {
          if (employee.id != id) return employee;
          return employee.copyWith(
            name: name,
            rate: rate,
            regularHours: regularHours,
            overtimeHours: overtimeHours,
            commission: commission,
            tips: tips,
          );
        })
        .toList(growable: false);

    _payroll = _payroll.copyWith(employees: employees);
    _rebuildState();
    _notify();
  }

  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;
    _isLoading = isLoading;
    _rebuildState();
    _notify();
  }

  void _setSaving(bool isSaving) {
    if (_isSaving == isSaving) return;
    _isSaving = isSaving;
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
      isSaving: _isSaving,
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
          final PayrollRecord periodForExpensePayDate = _payroll.copyWith(
            payDate: transactionDate,
          );
          return RecurrenceSchedule.isSameDate(
                periodForExpensePayDate.payPeriodStart,
                payPeriodStart,
              ) &&
              RecurrenceSchedule.isSameDate(
                periodForExpensePayDate.payPeriodEnd,
                payPeriodEnd,
              );
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

  String _newEmployeeId() {
    return 'payroll-employee-${AppClock.now.microsecondsSinceEpoch}-${_employeeIdCounter++}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

double _roundMoney(double value) => (value * 100).roundToDouble() / 100;
