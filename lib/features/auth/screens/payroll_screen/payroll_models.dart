import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/recurrence_schedule.dart';

enum PayrollSchedule {
  biWeekly,
  monthly;

  String get label {
    return switch (this) {
      PayrollSchedule.biWeekly => 'Bi Weekly',
      PayrollSchedule.monthly => 'Monthly',
    };
  }

  String get reminderFrequency {
    return switch (this) {
      PayrollSchedule.biWeekly => RecurrenceSchedule.biweekly,
      PayrollSchedule.monthly => RecurrenceSchedule.monthly,
    };
  }

  static PayrollSchedule fromLabel(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(' ', '');
    return switch (normalized) {
      'biweekly' => PayrollSchedule.biWeekly,
      'monthly' => PayrollSchedule.monthly,
      _ => PayrollSchedule.biWeekly,
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

  const PayrollEmployee({
    required this.id,
    required this.name,
    this.rate = 0,
    this.regularHours = 0,
    this.overtimeHours = 0,
    this.commission = 0,
    this.tips = 0,
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
  }) {
    return PayrollEmployee(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      regularHours: regularHours ?? this.regularHours,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      commission: commission ?? this.commission,
      tips: tips ?? this.tips,
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
  };
}

class PayrollRecord {
  final String id;
  final DateTime payDate;
  final PayrollSchedule schedule;
  final int processDaysBefore;
  final List<PayrollEmployee> employees;
  final String syncedExpenseId;
  final String reminderSeriesId;

  const PayrollRecord({
    required this.id,
    required this.payDate,
    required this.schedule,
    required this.processDaysBefore,
    required this.employees,
    this.syncedExpenseId = '',
    this.reminderSeriesId = '',
  });

  factory PayrollRecord.draft({required String id, DateTime? payDate}) {
    return PayrollRecord(
      id: id,
      payDate: _dateOnly(payDate ?? AppClock.now),
      schedule: PayrollSchedule.biWeekly,
      processDaysBefore: 7,
      employees: defaultEmployees,
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
      payDate: _dateOnly(_asDate(json['payDate'])),
      schedule: PayrollSchedule.fromLabel(_asString(json['schedule'])),
      processDaysBefore: _asInt(
        json['processDaysBefore'],
        fallback: 7,
      ).clamp(1, 31).toInt(),
      employees: List<PayrollEmployee>.unmodifiable(employees),
      syncedExpenseId: _asString(json['syncedExpenseId']),
      reminderSeriesId: _asString(json['reminderSeriesId']),
    );
  }

  static const List<PayrollEmployee> defaultEmployees = <PayrollEmployee>[
    PayrollEmployee(id: 'employee-jack-nicholson', name: 'Jack Nicholson'),
    PayrollEmployee(id: 'employee-waylon-dalton', name: 'Waylon Dalton'),
    PayrollEmployee(id: 'employee-abdullah-lang', name: 'Abdullah Lang'),
    PayrollEmployee(
      id: 'employee-justine-henderson',
      name: 'Justine Henderson',
    ),
    PayrollEmployee(id: 'employee-joanna-shaffer', name: 'Joanna Shaffer'),
    PayrollEmployee(id: 'employee-mathias-little', name: 'Mathias Little'),
  ];

  DateTime get processDate =>
      _dateOnly(payDate).subtract(Duration(days: processDaysBefore));

  double get totalPay => _roundMoney(
    employees.fold<double>(
      0,
      (double total, PayrollEmployee employee) => total + employee.totalPay,
    ),
  );

  DateTime get payPeriodStart {
    if (schedule == PayrollSchedule.monthly) {
      final previousMonth = DateTime(payDate.year, payDate.month - 1);
      return DateTime(previousMonth.year, previousMonth.month);
    }

    return payPeriodEnd.subtract(const Duration(days: 13));
  }

  DateTime get payPeriodEnd {
    if (schedule == PayrollSchedule.monthly) {
      return DateTime(payDate.year, payDate.month, 0);
    }

    return _dateOnly(payDate).subtract(const Duration(days: 6));
  }

  String get processInstruction =>
      'Payroll will be processed $processDaysBefore days before the payroll date.';

  PayrollRecord copyWith({
    String? id,
    DateTime? payDate,
    PayrollSchedule? schedule,
    int? processDaysBefore,
    List<PayrollEmployee>? employees,
    String? syncedExpenseId,
    String? reminderSeriesId,
  }) {
    return PayrollRecord(
      id: id ?? this.id,
      payDate: _dateOnly(payDate ?? this.payDate),
      schedule: schedule ?? this.schedule,
      processDaysBefore: (processDaysBefore ?? this.processDaysBefore)
          .clamp(1, 31)
          .toInt(),
      employees: List<PayrollEmployee>.unmodifiable(
        employees ?? this.employees,
      ),
      syncedExpenseId: syncedExpenseId ?? this.syncedExpenseId,
      reminderSeriesId: reminderSeriesId ?? this.reminderSeriesId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'payDate': payDate.toIso8601String(),
    'schedule': schedule.label,
    'processDaysBefore': processDaysBefore,
    'employees': employees
        .map((PayrollEmployee employee) => employee.toJson())
        .toList(growable: false),
    'syncedExpenseId': syncedExpenseId,
    'reminderSeriesId': reminderSeriesId,
  };
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

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

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _asDate(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? AppClock.now;
}
