class EmployeePayrollSetting {
  final EmployeePayrollSchedule schedule;
  final EmployeePayrollEndingDay? endingDay;
  final int? monthlyEndingDay;
  final int? firstSemiMonthlyEndingDay;
  final int? secondSemiMonthlyEndingDay;
  final DateTime firstPeriodEndDate;
  final EmployeePayDateSetting payDateSetting;
  final EmployeeProcessPayrollSetting processPayrollSetting;
  final int paidAfterPeriodEndDays;
  final int remindAfterPeriodEndDays;

  const EmployeePayrollSetting({
    required this.schedule,
    required this.firstPeriodEndDate,
    this.endingDay,
    this.monthlyEndingDay,
    this.firstSemiMonthlyEndingDay,
    this.secondSemiMonthlyEndingDay,
    this.payDateSetting = EmployeePayDateSetting.afterPeriodEnd,
    this.processPayrollSetting = EmployeeProcessPayrollSetting.manualReview,
    this.paidAfterPeriodEndDays = 0,
    this.remindAfterPeriodEndDays = 0,
  });

  factory EmployeePayrollSetting.fromJson(Map<dynamic, dynamic> json) {
    return EmployeePayrollSetting(
      schedule: EmployeePayrollSchedule.fromValue(json['schedule']),
      endingDay: EmployeePayrollEndingDay.fromValue(json['endingDay']),
      monthlyEndingDay: _asMonthDay(json['monthlyEndingDay']),
      firstSemiMonthlyEndingDay: _asMonthDay(json['firstSemiMonthlyEndingDay']),
      secondSemiMonthlyEndingDay: _asMonthDay(
        json['secondSemiMonthlyEndingDay'],
      ),
      firstPeriodEndDate: _asDate(json['firstPeriodEndDate']) ?? DateTime(2000),
      payDateSetting: EmployeePayDateSetting.fromValue(json['payDateSetting']),
      processPayrollSetting: EmployeeProcessPayrollSetting.fromValue(
        json['processPayrollSetting'],
      ),
      paidAfterPeriodEndDays: _asNonNegativeInt(json['paidAfterPeriodEndDays']),
      remindAfterPeriodEndDays: _asNonNegativeInt(
        json['remindAfterPeriodEndDays'],
      ),
    );
  }

  EmployeePayrollSetting copyWith({
    EmployeePayrollSchedule? schedule,
    EmployeePayrollEndingDay? endingDay,
    bool clearEndingDay = false,
    int? monthlyEndingDay,
    bool clearMonthlyEndingDay = false,
    int? firstSemiMonthlyEndingDay,
    bool clearFirstSemiMonthlyEndingDay = false,
    int? secondSemiMonthlyEndingDay,
    bool clearSecondSemiMonthlyEndingDay = false,
    DateTime? firstPeriodEndDate,
    EmployeePayDateSetting? payDateSetting,
    EmployeeProcessPayrollSetting? processPayrollSetting,
    int? paidAfterPeriodEndDays,
    int? remindAfterPeriodEndDays,
  }) {
    return EmployeePayrollSetting(
      schedule: schedule ?? this.schedule,
      endingDay: clearEndingDay ? null : endingDay ?? this.endingDay,
      monthlyEndingDay: clearMonthlyEndingDay
          ? null
          : monthlyEndingDay ?? this.monthlyEndingDay,
      firstSemiMonthlyEndingDay: clearFirstSemiMonthlyEndingDay
          ? null
          : firstSemiMonthlyEndingDay ?? this.firstSemiMonthlyEndingDay,
      secondSemiMonthlyEndingDay: clearSecondSemiMonthlyEndingDay
          ? null
          : secondSemiMonthlyEndingDay ?? this.secondSemiMonthlyEndingDay,
      firstPeriodEndDate: firstPeriodEndDate ?? this.firstPeriodEndDate,
      payDateSetting: payDateSetting ?? this.payDateSetting,
      processPayrollSetting:
          processPayrollSetting ?? this.processPayrollSetting,
      paidAfterPeriodEndDays: _clampNonNegativeInt(
        paidAfterPeriodEndDays ?? this.paidAfterPeriodEndDays,
      ),
      remindAfterPeriodEndDays: _clampNonNegativeInt(
        remindAfterPeriodEndDays ?? this.remindAfterPeriodEndDays,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schedule': schedule.name,
      if (endingDay != null) 'endingDay': endingDay!.name,
      if (monthlyEndingDay != null) 'monthlyEndingDay': monthlyEndingDay,
      if (firstSemiMonthlyEndingDay != null)
        'firstSemiMonthlyEndingDay': firstSemiMonthlyEndingDay,
      if (secondSemiMonthlyEndingDay != null)
        'secondSemiMonthlyEndingDay': secondSemiMonthlyEndingDay,
      'firstPeriodEndDate': firstPeriodEndDate.toIso8601String(),
      'payDateSetting': payDateSetting.name,
      'processPayrollSetting': processPayrollSetting.name,
      'paidAfterPeriodEndDays': paidAfterPeriodEndDays,
      'remindAfterPeriodEndDays': remindAfterPeriodEndDays,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is EmployeePayrollSetting &&
        other.schedule == schedule &&
        other.endingDay == endingDay &&
        other.monthlyEndingDay == monthlyEndingDay &&
        other.firstSemiMonthlyEndingDay == firstSemiMonthlyEndingDay &&
        other.secondSemiMonthlyEndingDay == secondSemiMonthlyEndingDay &&
        other.firstPeriodEndDate == firstPeriodEndDate &&
        other.payDateSetting == payDateSetting &&
        other.processPayrollSetting == processPayrollSetting &&
        other.paidAfterPeriodEndDays == paidAfterPeriodEndDays &&
        other.remindAfterPeriodEndDays == remindAfterPeriodEndDays;
  }

  @override
  int get hashCode => Object.hash(
    schedule,
    endingDay,
    monthlyEndingDay,
    firstSemiMonthlyEndingDay,
    secondSemiMonthlyEndingDay,
    firstPeriodEndDate,
    payDateSetting,
    processPayrollSetting,
    paidAfterPeriodEndDays,
    remindAfterPeriodEndDays,
  );
}

enum EmployeePayrollSchedule {
  none('None'),
  weekly('Weekly', 7),
  biWeekly('Bi Weekly', 14),
  monthly('Monthly'),
  semiMonthly('Semi Monthly');

  final String label;
  final int? periodLengthDays;

  const EmployeePayrollSchedule(this.label, [this.periodLengthDays]);

  bool get usesWeekdayEndingDay {
    return this == EmployeePayrollSchedule.weekly ||
        this == EmployeePayrollSchedule.biWeekly;
  }

  bool get usesMonthlyEndingDay {
    return this == EmployeePayrollSchedule.monthly;
  }

  bool get usesSemiMonthlyEndingDays {
    return this == EmployeePayrollSchedule.semiMonthly;
  }

  static EmployeePayrollSchedule fromValue(Object? value) {
    final String normalized = value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');
    return switch (normalized) {
      'none' => EmployeePayrollSchedule.none,
      'weekly' => EmployeePayrollSchedule.weekly,
      'biweekly' => EmployeePayrollSchedule.biWeekly,
      'monthly' => EmployeePayrollSchedule.monthly,
      'semimonthly' => EmployeePayrollSchedule.semiMonthly,
      _ => EmployeePayrollSchedule.none,
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

  static EmployeePayrollEndingDay? fromValue(Object? value) {
    if (value == null) return null;
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
      _ => null,
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

int? _asMonthDay(Object? value) {
  if (value == null) return null;
  final int? day = int.tryParse(value.toString());
  if (day == null || day < 1 || day > 31) return null;
  return day;
}

int _asNonNegativeInt(Object? value) {
  final int? parsed = int.tryParse(value?.toString() ?? '');
  return _clampNonNegativeInt(parsed ?? 0);
}

int _clampNonNegativeInt(int value) {
  return value < 0 ? 0 : value;
}
