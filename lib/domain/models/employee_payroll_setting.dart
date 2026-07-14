class EmployeePayrollSetting {
  final EmployeePayrollSchedule schedule;
  final EmployeePayrollEndingDay endingDay;
  final DateTime firstPeriodEndDate;
  final EmployeePayDateSetting payDateSetting;
  final EmployeeProcessPayrollSetting processPayrollSetting;

  const EmployeePayrollSetting({
    required this.schedule,
    required this.endingDay,
    required this.firstPeriodEndDate,
    this.payDateSetting = EmployeePayDateSetting.afterPeriodEnd,
    this.processPayrollSetting = EmployeeProcessPayrollSetting.manualReview,
  });

  factory EmployeePayrollSetting.fromJson(Map<dynamic, dynamic> json) {
    return EmployeePayrollSetting(
      schedule: EmployeePayrollSchedule.fromValue(json['schedule']),
      endingDay: EmployeePayrollEndingDay.fromValue(json['endingDay']),
      firstPeriodEndDate: _asDate(json['firstPeriodEndDate']) ?? DateTime(2000),
      payDateSetting: EmployeePayDateSetting.fromValue(json['payDateSetting']),
      processPayrollSetting: EmployeeProcessPayrollSetting.fromValue(
        json['processPayrollSetting'],
      ),
    );
  }

  EmployeePayrollSetting copyWith({
    EmployeePayrollSchedule? schedule,
    EmployeePayrollEndingDay? endingDay,
    DateTime? firstPeriodEndDate,
    EmployeePayDateSetting? payDateSetting,
    EmployeeProcessPayrollSetting? processPayrollSetting,
  }) {
    return EmployeePayrollSetting(
      schedule: schedule ?? this.schedule,
      endingDay: endingDay ?? this.endingDay,
      firstPeriodEndDate: firstPeriodEndDate ?? this.firstPeriodEndDate,
      payDateSetting: payDateSetting ?? this.payDateSetting,
      processPayrollSetting:
          processPayrollSetting ?? this.processPayrollSetting,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schedule': schedule.name,
    'endingDay': endingDay.name,
    'firstPeriodEndDate': firstPeriodEndDate.toIso8601String(),
    'payDateSetting': payDateSetting.name,
    'processPayrollSetting': processPayrollSetting.name,
  };

  @override
  bool operator ==(Object other) {
    return other is EmployeePayrollSetting &&
        other.schedule == schedule &&
        other.endingDay == endingDay &&
        other.firstPeriodEndDate == firstPeriodEndDate &&
        other.payDateSetting == payDateSetting &&
        other.processPayrollSetting == processPayrollSetting;
  }

  @override
  int get hashCode => Object.hash(
    schedule,
    endingDay,
    firstPeriodEndDate,
    payDateSetting,
    processPayrollSetting,
  );
}

enum EmployeePayrollSchedule {
  weekly('Weekly', 7),
  biWeekly('Bi Weekly', 14);

  final String label;
  final int periodLengthDays;

  const EmployeePayrollSchedule(this.label, this.periodLengthDays);

  static EmployeePayrollSchedule fromValue(Object? value) {
    final String normalized = value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');
    return switch (normalized) {
      'weekly' => EmployeePayrollSchedule.weekly,
      'biweekly' => EmployeePayrollSchedule.biWeekly,
      _ => EmployeePayrollSchedule.biWeekly,
    };
  }
}

enum EmployeePayrollEndingDay {
  monday('Monday', DateTime.monday),
  tuesday('Tuesday', DateTime.tuesday),
  wednesday('Wednesday', DateTime.wednesday),
  thursday('Thursday', DateTime.thursday),
  friday('Friday', DateTime.friday),
  saturday('Saturday', DateTime.saturday),
  sunday('Sunday', DateTime.sunday);

  final String label;
  final int weekday;

  const EmployeePayrollEndingDay(this.label, this.weekday);

  static EmployeePayrollEndingDay fromDate(DateTime date) {
    return fromWeekday(date.weekday);
  }

  static EmployeePayrollEndingDay fromWeekday(int weekday) {
    return EmployeePayrollEndingDay.values.firstWhere(
      (EmployeePayrollEndingDay day) => day.weekday == weekday,
      orElse: () => EmployeePayrollEndingDay.sunday,
    );
  }

  static EmployeePayrollEndingDay fromValue(Object? value) {
    final String normalized = value.toString().trim().toLowerCase().replaceAll(
      '_',
      '',
    );
    return switch (normalized) {
      'monday' => EmployeePayrollEndingDay.monday,
      'tuesday' => EmployeePayrollEndingDay.tuesday,
      'wednesday' => EmployeePayrollEndingDay.wednesday,
      'thursday' => EmployeePayrollEndingDay.thursday,
      'friday' => EmployeePayrollEndingDay.friday,
      'saturday' => EmployeePayrollEndingDay.saturday,
      'sunday' => EmployeePayrollEndingDay.sunday,
      _ => EmployeePayrollEndingDay.sunday,
    };
  }
}

enum EmployeePayDateSetting {
  sameDay('Same day'),
  afterPeriodEnd('After period end'),
  manual('Manual');

  final String label;

  const EmployeePayDateSetting(this.label);

  static EmployeePayDateSetting fromValue(Object? value) {
    final String normalized = value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll(' ', '');
    return switch (normalized) {
      'sameday' => EmployeePayDateSetting.sameDay,
      'manual' => EmployeePayDateSetting.manual,
      _ => EmployeePayDateSetting.afterPeriodEnd,
    };
  }
}

enum EmployeeProcessPayrollSetting {
  manualReview('Manual review'),
  oneDayBeforePayDate('One day before pay date'),
  twoDaysBeforePayDate('Two days before pay date');

  final String label;

  const EmployeeProcessPayrollSetting(this.label);

  static EmployeeProcessPayrollSetting fromValue(Object? value) {
    final String normalized = value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll(' ', '');
    return switch (normalized) {
      'onedaybeforepaydate' =>
        EmployeeProcessPayrollSetting.oneDayBeforePayDate,
      'twodaysbeforepaydate' =>
        EmployeeProcessPayrollSetting.twoDaysBeforePayDate,
      _ => EmployeeProcessPayrollSetting.manualReview,
    };
  }
}

EmployeePayrollSetting? employeePayrollSettingFromJson(Object? value) {
  if (value is! Map) return null;
  final DateTime? firstPeriodEndDate = _asDate(value['firstPeriodEndDate']);
  if (firstPeriodEndDate == null) return null;
  return EmployeePayrollSetting.fromJson(value);
}

DateTime? _asDate(Object? value) {
  if (value == null) return null;
  final String text = value.toString().trim();
  if (text.isEmpty) return null;

  final DateTime? isoDate = DateTime.tryParse(text);
  if (isoDate != null) {
    return DateTime(isoDate.year, isoDate.month, isoDate.day);
  }

  final List<String> parts = text.split('/');
  if (parts.length != 3) return null;
  final int? month = int.tryParse(parts[0]);
  final int? day = int.tryParse(parts[1]);
  final int? year = int.tryParse(parts[2]);
  if (month == null || day == null || year == null) return null;
  return DateTime(year < 100 ? 2000 + year : year, month, day);
}
