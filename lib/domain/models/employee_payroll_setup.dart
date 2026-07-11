enum EmployeePayrollSchedule {
  weekly,
  biweekly,
  biMonthly,
  monthly;

  String get label {
    return switch (this) {
      EmployeePayrollSchedule.weekly => 'Weekly',
      EmployeePayrollSchedule.biweekly => 'Biweekly',
      EmployeePayrollSchedule.biMonthly => 'Bi Monthly',
      EmployeePayrollSchedule.monthly => 'Monthly',
    };
  }

  String get statusLabel {
    return switch (this) {
      EmployeePayrollSchedule.weekly => 'Weekly',
      EmployeePayrollSchedule.biweekly => 'Biweekly',
      EmployeePayrollSchedule.biMonthly => 'BiMonthly',
      EmployeePayrollSchedule.monthly => 'Monthly',
    };
  }

  bool get requiresWeekday {
    return switch (this) {
      EmployeePayrollSchedule.weekly ||
      EmployeePayrollSchedule.biweekly => true,
      EmployeePayrollSchedule.biMonthly ||
      EmployeePayrollSchedule.monthly => false,
    };
  }

  static EmployeePayrollSchedule? fromJson(Object? value) {
    final String normalized = value.toString().trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
    return switch (normalized) {
      'weekly' => EmployeePayrollSchedule.weekly,
      'biweekly' => EmployeePayrollSchedule.biweekly,
      'bimonthly' => EmployeePayrollSchedule.biMonthly,
      'monthly' => EmployeePayrollSchedule.monthly,
      _ => null,
    };
  }
}

enum EmployeePayrollWeekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get label {
    return switch (this) {
      EmployeePayrollWeekday.monday => 'Monday',
      EmployeePayrollWeekday.tuesday => 'Tuesday',
      EmployeePayrollWeekday.wednesday => 'Wednesday',
      EmployeePayrollWeekday.thursday => 'Thursday',
      EmployeePayrollWeekday.friday => 'Friday',
      EmployeePayrollWeekday.saturday => 'Saturday',
      EmployeePayrollWeekday.sunday => 'Sunday',
    };
  }

  static EmployeePayrollWeekday? fromJson(Object? value) {
    final String normalized = value.toString().trim().toLowerCase();
    return switch (normalized) {
      'monday' => EmployeePayrollWeekday.monday,
      'tuesday' => EmployeePayrollWeekday.tuesday,
      'wednesday' => EmployeePayrollWeekday.wednesday,
      'thursday' => EmployeePayrollWeekday.thursday,
      'friday' => EmployeePayrollWeekday.friday,
      'saturday' => EmployeePayrollWeekday.saturday,
      'sunday' => EmployeePayrollWeekday.sunday,
      _ => null,
    };
  }
}

class EmployeePayrollSetup {
  final EmployeePayrollSchedule schedule;
  final EmployeePayrollWeekday? weekday;
  final int paidAfterDays;
  final int remindAfterDays;
  final double rate;

  const EmployeePayrollSetup({
    required this.schedule,
    required this.weekday,
    required this.paidAfterDays,
    required this.remindAfterDays,
    required this.rate,
  });

  factory EmployeePayrollSetup.fromJson(Map<dynamic, dynamic> json) {
    final EmployeePayrollSchedule? schedule = EmployeePayrollSchedule.fromJson(
      json['schedule'],
    );
    if (schedule == null) {
      throw const FormatException('Missing payroll schedule');
    }

    return EmployeePayrollSetup(
      schedule: schedule,
      weekday: EmployeePayrollWeekday.fromJson(json['weekday']),
      paidAfterDays: _asInt(json['paidAfterDays']),
      remindAfterDays: _asInt(json['remindAfterDays']),
      rate: _asDouble(json['rate']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schedule': schedule.name,
    'weekday': weekday?.name,
    'paidAfterDays': paidAfterDays,
    'remindAfterDays': remindAfterDays,
    'rate': rate,
  };

  EmployeePayrollSetup copyWith({
    EmployeePayrollSchedule? schedule,
    EmployeePayrollWeekday? weekday,
    bool clearWeekday = false,
    int? paidAfterDays,
    int? remindAfterDays,
    double? rate,
  }) {
    return EmployeePayrollSetup(
      schedule: schedule ?? this.schedule,
      weekday: clearWeekday ? null : weekday ?? this.weekday,
      paidAfterDays: paidAfterDays ?? this.paidAfterDays,
      remindAfterDays: remindAfterDays ?? this.remindAfterDays,
      rate: rate ?? this.rate,
    );
  }
}

EmployeePayrollSetup? employeePayrollSetupFromJson(Object? value) {
  if (value is! Map) return null;

  try {
    return EmployeePayrollSetup.fromJson(value);
  } catch (_) {
    return null;
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
