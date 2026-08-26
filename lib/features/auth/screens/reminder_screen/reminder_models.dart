part of 'reminder_screen.dart';

sealed class _ReminderListEntry {
  const _ReminderListEntry();
}

final class _ReminderRecordEntry extends _ReminderListEntry {
  final ReminderRecord record;
  final double remainingBalanceThisYear;

  const _ReminderRecordEntry({
    required this.record,
    required this.remainingBalanceThisYear,
  });
}

final class _EmptyReminderEntry extends _ReminderListEntry {
  const _EmptyReminderEntry();
}

enum _ReminderViewMode {
  week('Week'),
  month('Month');

  final String label;

  const _ReminderViewMode(this.label);
}

class _ReminderViewState {
  final bool isLoading;
  final _ReminderViewMode viewMode;
  final DateTime visibleMonth;
  final DateTime visibleWeekStart;
  final DateTime periodStart;
  final DateTime periodEndExclusive;
  final List<ReminderRecord> periodReminders;
  final List<_CalendarDayModel> calendarDays;
  final List<_ReminderListEntry> entries;
  final Map<String, List<ReminderRecord>> remindersByDate;
  final double availableFunds;
  final double spentInPeriod;

  const _ReminderViewState({
    required this.isLoading,
    required this.viewMode,
    required this.visibleMonth,
    required this.visibleWeekStart,
    required this.periodStart,
    required this.periodEndExclusive,
    required this.periodReminders,
    required this.calendarDays,
    required this.entries,
    required this.remindersByDate,
    required this.availableFunds,
    required this.spentInPeriod,
  });

  factory _ReminderViewState.initial(
    DateTime visibleMonth,
    DateTime visibleWeekStart,
  ) {
    return _ReminderViewState(
      isLoading: true,
      viewMode: _ReminderViewMode.month,
      visibleMonth: visibleMonth,
      visibleWeekStart: visibleWeekStart,
      periodStart: visibleMonth,
      periodEndExclusive: DateTime(visibleMonth.year, visibleMonth.month + 1),
      periodReminders: const <ReminderRecord>[],
      calendarDays: const <_CalendarDayModel>[],
      entries: const <_ReminderListEntry>[],
      remindersByDate: const <String, List<ReminderRecord>>{},
      availableFunds: 0,
      spentInPeriod: 0,
    );
  }

  bool get hasVisibleReminders => periodReminders.isNotEmpty;

  String get spentLabel {
    return viewMode == _ReminderViewMode.week
        ? 'Spent this week'
        : 'Spent this month';
  }

  String get rangeLabel {
    return viewMode == _ReminderViewMode.week
        ? _ReminderDateUtils.weekRange(periodStart)
        : _ReminderDateUtils.monthRange(visibleMonth);
  }
}

class _CalendarDayModel {
  final DateTime date;
  final bool isInVisibleMonth;
  final bool isInSelectedPeriod;
  final bool isToday;
  final List<ReminderRecord> reminders;

  const _CalendarDayModel({
    required this.date,
    required this.isInVisibleMonth,
    required this.isInSelectedPeriod,
    required this.isToday,
    required this.reminders,
  });

  bool get hasReminders => reminders.isNotEmpty;
}

class _AmountEditResult {
  final double amount;
  final bool applyToSeries;

  const _AmountEditResult({required this.amount, required this.applyToSeries});
}

class _ReminderFormData {
  DateTime date;
  String category;
  String reminderCount;
  final TextEditingController amountController;

  _ReminderFormData({required this.date})
    : category = ExpenseCategory.energy.name,
      reminderCount = _reminderCounts.first,
      amountController = TextEditingController();

  ReminderDraft toDraft() {
    return ReminderDraft(
      date: date,
      category: category,
      amount: parseMoney(amountController.text),
      reminderCount: reminderCount,
      payee: category,
    );
  }

  void dispose() {
    amountController.dispose();
  }
}

class _ReminderDateUtils {
  const _ReminderDateUtils._();

  static DateTime monthStart(DateTime value) {
    return DateTime(value.year, value.month);
  }

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime weekStart(DateTime value) {
    final DateTime date = dateOnly(value);
    return date.subtract(Duration(days: date.weekday % 7));
  }

  static List<DateTime> weekDates(DateTime weekStart) {
    final DateTime start = dateOnly(weekStart);
    return List<DateTime>.generate(
      7,
      (int index) => start.add(Duration(days: index)),
      growable: false,
    );
  }

  static String dateKey(DateTime value) {
    final DateTime date = dateOnly(value);
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String fullDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  static String compactDate(DateTime date, {bool includeYear = false}) {
    final String text = '${_shortMonthNames[date.month]} ${date.day}';
    return includeYear ? '$text, ${date.year}' : text;
  }

  static String weekRange(DateTime weekStart) {
    final DateTime start = dateOnly(weekStart);
    final DateTime end = start.add(const Duration(days: 6));
    if (start.year == end.year && start.month == end.month) {
      return '${compactDate(start)} - ${end.day}, ${end.year}';
    }
    return '${compactDate(start)} - ${compactDate(end, includeYear: true)}';
  }

  static String monthRange(DateTime month) {
    final DateTime first = DateTime(month.year, month.month);
    final DateTime last = DateTime(month.year, month.month + 1, 0);
    return '${compactDate(first)} - ${compactDate(last, includeYear: true)}';
  }

  static bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static List<DateTime> calendarDates(DateTime month) {
    final DateTime first = DateTime(month.year, month.month);
    final DateTime last = DateTime(month.year, month.month + 1, 0);
    final DateTime start = first.subtract(Duration(days: first.weekday % 7));
    final DateTime end = last.add(Duration(days: 6 - (last.weekday % 7)));
    final int dayCount = end.difference(start).inDays + 1;
    return List<DateTime>.generate(
      dayCount,
      (int index) => start.add(Duration(days: index)),
      growable: false,
    );
  }
}

class _ReminderTokens {
  const _ReminderTokens._();

  static const Color screenBackground = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color appBarIcon = Color(0xFF1F2937);
  static const Color textStrong = Color(0xFF111827);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF6B7280);
  static const Color textInactive = Color(0xFF9CA3AF);
  static const Color labelStrong = Color(0xFF283154);
  static const Color compactActionBackground = Colors.white;
  static const Color border = Color(0xFFE5E7EB);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFEAF8EF);
  static const Color today = Color(0xFFFACC15);
  static const Color warning = Color(0xFFEAB308);
  static const Color blue = Color(0xFF2563EB);
  static const Color navy = Color(0xFF0F2D4A);
  static const Color iconBlue = Color(0xFF60A5FA);
  static const Color inputBorder = Color(0xFF9CA3AF);

  static const double cardRadius = 4;
  static const double controlRadius = 3;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 10, 16, 20);
  static const EdgeInsets createPagePadding = EdgeInsets.fromLTRB(
    16,
    18,
    16,
    24,
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> inputShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const TextStyle appBarTitle = TextStyle(
    color: Colors.black87,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle monthTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle summaryLabel = TextStyle(
    color: textStrong,
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle summaryAmount = TextStyle(
    color: warning,
    fontSize: 20,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle sectionLabel = TextStyle(
    color: textSubtle,
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.3,
  );
  static const TextStyle weekdayLabel = TextStyle(
    color: textMuted,
    fontSize: 9,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle fieldLabel = TextStyle(
    color: labelStrong,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
  );
  static const TextStyle emptyLabel = TextStyle(
    color: textSubtle,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle addButtonLabel = TextStyle(
    color: textStrong,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle inputText = TextStyle(
    color: textStrong,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}

const List<String> _reminderCounts = <String>[
  'Monthly',
  'Just one',
  'Weekly',
  'Biweekly',
  'Semi-monthly',
  'Quarterly',
  'Yearly',
];

const List<String> _monthNames = <String>[
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _shortMonthNames = <String>[
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
