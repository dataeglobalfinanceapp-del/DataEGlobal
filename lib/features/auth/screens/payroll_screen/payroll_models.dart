import 'package:savetep/domain/models/employee_payroll_setting.dart';
import 'package:savetep/services/app_clock.dart';

import 'payroll_pay_date_validator.dart';

enum PayrollAction {
  same('Same'),
  change('Change'),
  vacation('Vacation'),
  off('Off');

  final String label;

  const PayrollAction(this.label);

  bool get clearsPayroll {
    return switch (this) {
      PayrollAction.vacation || PayrollAction.off => true,
      PayrollAction.same || PayrollAction.change => false,
    };
  }

  static PayrollAction fromLabel(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'change' => PayrollAction.change,
      'vacation' => PayrollAction.vacation,
      'off' => PayrollAction.off,
      _ => PayrollAction.same,
    };
  }
}

class PayrollEmployee {
  final String id;
  final String name;
  final double rate;
  final double regularHours;
  final double overtimeHours;
  final double commission;
  final double tips;
  final String birthday;
  final String phone;
  final String address;
  final String jobType;
  final String dateHire;
  final String payMethod;
  final String linkW4;
  final EmployeePayrollSetting? payrollSetting;
  final PayrollAction payrollAction;
  final bool isPayrollConfirmed;

  const PayrollEmployee({
    required this.id,
    required this.name,
    this.rate = 0,
    this.regularHours = 0,
    this.overtimeHours = 0,
    this.commission = 0,
    this.tips = 0,
    this.birthday = '',
    this.phone = '',
    this.address = '',
    this.jobType = '',
    this.dateHire = '',
    this.payMethod = '',
    this.linkW4 = '',
    this.payrollSetting,
    this.payrollAction = PayrollAction.same,
    this.isPayrollConfirmed = false,
  });

  factory PayrollEmployee.fromJson(Map<dynamic, dynamic> json) {
    return PayrollEmployee(
      id: _asString(json['id'], fallback: _fallbackId('payroll-employee')),
      name: _asString(json['name']),
      rate: _asDouble(json['rate']),
      regularHours: _asDouble(json['regularHours']),
      overtimeHours: _asDouble(json['overtimeHours']),
      commission: _asDouble(json['commission']),
      tips: _asDouble(json['tips']),
      birthday: _asString(json['birthday']),
      phone: _asString(json['phone']),
      address: _asString(json['address']),
      jobType: _asString(json['jobType']),
      dateHire: _asString(json['dateHire']),
      payMethod: _asString(json['payMethod']),
      linkW4: _asString(json['linkW4']),
      payrollSetting: employeePayrollSettingFromJson(json['payrollSetting']),
      payrollAction: PayrollAction.fromLabel(_asString(json['payrollAction'])),
      isPayrollConfirmed: json['isPayrollConfirmed'] == true,
    );
  }

  double get regularPay => rate * regularHours;

  double get overtimePay => rate * 1.5 * overtimeHours;

  double get totalPay =>
      _roundMoney(regularPay + overtimePay + commission + tips);

  PayrollEmployee copyWith({
    String? id,
    String? name,
    double? rate,
    double? regularHours,
    double? overtimeHours,
    double? commission,
    double? tips,
    String? birthday,
    String? phone,
    String? address,
    String? jobType,
    String? dateHire,
    String? payMethod,
    String? linkW4,
    EmployeePayrollSetting? payrollSetting,
    PayrollAction? payrollAction,
    bool? isPayrollConfirmed,
  }) {
    return PayrollEmployee(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      regularHours: regularHours ?? this.regularHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      commission: commission ?? this.commission,
      tips: tips ?? this.tips,
      birthday: birthday ?? this.birthday,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      jobType: jobType ?? this.jobType,
      dateHire: dateHire ?? this.dateHire,
      payMethod: payMethod ?? this.payMethod,
      linkW4: linkW4 ?? this.linkW4,
      payrollSetting: payrollSetting ?? this.payrollSetting,
      payrollAction: payrollAction ?? this.payrollAction,
      isPayrollConfirmed: isPayrollConfirmed ?? this.isPayrollConfirmed,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'rate': rate,
    'regularHours': regularHours,
    'overtimeHours': overtimeHours,
    'commission': commission,
    'tips': tips,
    'birthday': birthday,
    'phone': phone,
    'address': address,
    'jobType': jobType,
    'dateHire': dateHire,
    'payMethod': payMethod,
    'linkW4': linkW4,
    if (payrollSetting != null) 'payrollSetting': payrollSetting!.toJson(),
    'payrollAction': payrollAction.label,
    'isPayrollConfirmed': isPayrollConfirmed,
  };
}

class PayrollRecord {
  final String id;
  final DateTime payDate;
  final List<PayrollEmployee> employees;
  final String syncedExpenseId;

  const PayrollRecord({
    required this.id,
    required this.payDate,
    required this.employees,
    this.syncedExpenseId = '',
  });

  factory PayrollRecord.draft({required String id, DateTime? payDate}) {
    return PayrollRecord(
      id: id,
      payDate: PayrollPayDateValidator.normalizePayDate(
        payDate ?? AppClock.now,
      ),
      employees: const <PayrollEmployee>[],
    );
  }

  factory PayrollRecord.fromJson(Map<dynamic, dynamic> json) {
    final employeesJson = json['employees'];
    final employees = employeesJson is List
        ? employeesJson
              .whereType<Map>()
              .map(PayrollEmployee.fromJson)
              .toList(growable: false)
        : const <PayrollEmployee>[];

    return PayrollRecord(
      id: _asString(json['id'], fallback: _fallbackId('payroll')),
      payDate: PayrollPayDateValidator.normalizePayDate(
        _asDate(json['payDate']),
      ),
      employees: List<PayrollEmployee>.unmodifiable(employees),
      syncedExpenseId: _asString(json['syncedExpenseId']),
    );
  }

  double get totalPay => _roundMoney(
    employees.fold<double>(
      0,
      (double total, PayrollEmployee employee) => total + employee.totalPay,
    ),
  );

  int get unconfirmedEmployeeCount {
    return employees
        .where((PayrollEmployee employee) => !employee.isPayrollConfirmed)
        .length;
  }

  bool get allEmployeesConfirmed =>
      employees.isNotEmpty && unconfirmedEmployeeCount == 0;

  PayrollRecord copyWith({
    String? id,
    DateTime? payDate,
    List<PayrollEmployee>? employees,
    String? syncedExpenseId,
  }) {
    return PayrollRecord(
      id: id ?? this.id,
      payDate: PayrollPayDateValidator.normalizePayDate(
        payDate ?? this.payDate,
      ),
      employees: List<PayrollEmployee>.unmodifiable(
        employees ?? this.employees,
      ),
      syncedExpenseId: syncedExpenseId ?? this.syncedExpenseId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'payDate': payDate.toIso8601String(),
    'employees': employees
        .map((PayrollEmployee employee) => employee.toJson())
        .toList(growable: false),
    'syncedExpenseId': syncedExpenseId,
  };
}

double _roundMoney(double value) => (value * 100).roundToDouble() / 100;

int _fallbackIdCounter = 0;

String _fallbackId(String prefix) =>
    '$prefix-imported-${AppClock.now.microsecondsSinceEpoch}-${_fallbackIdCounter++}';

String _asString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _asDate(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? AppClock.now;
}
