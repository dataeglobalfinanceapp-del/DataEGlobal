part of 'reminder_screen.dart';

sealed class _ReminderListEntry {
  const _ReminderListEntry();
}

final class _ReminderRecordEntry extends _ReminderListEntry {
  final ReminderRecord record;

  const _ReminderRecordEntry(this.record);
}

final class _EmptyReminderEntry extends _ReminderListEntry {
  const _EmptyReminderEntry();
}

class _ReminderViewState {
  final bool isLoading;
  final DateTime visibleMonth;
  final List<ReminderRecord> monthReminders;
  final List<_CalendarDayModel> calendarDays;
  final List<_ReminderListEntry> entries;
  final Map<String, List<ReminderRecord>> remindersByDate;

  const _ReminderViewState({
    required this.isLoading,
    required this.visibleMonth,
    required this.monthReminders,
    required this.calendarDays,
    required this.entries,
    required this.remindersByDate,
  });

  factory _ReminderViewState.initial(DateTime visibleMonth) {
    return _ReminderViewState(
      isLoading: true,
      visibleMonth: visibleMonth,
      monthReminders: const <ReminderRecord>[],
      calendarDays: const <_CalendarDayModel>[],
      entries: const <_ReminderListEntry>[],
      remindersByDate: const <String, List<ReminderRecord>>{},
    );
  }
}

class _CalendarDayModel {
  final DateTime date;
  final bool isInVisibleMonth;
  final bool isToday;
  final List<ReminderRecord> reminders;

  const _CalendarDayModel({
    required this.date,
    required this.isInVisibleMonth,
    required this.isToday,
    required this.reminders,
  });

  bool get hasReminders => reminders.isNotEmpty;
}

enum _ReminderDetailAction { editAmount, delete, markFinished, postpone }

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
    : category = _categories.first,
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

  static bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static List<DateTime> calendarDates(DateTime month) {
    final DateTime first = DateTime(month.year, month.month);
    final DateTime start = first.subtract(Duration(days: first.weekday % 7));
    return List<DateTime>.generate(
      42,
      (int index) => start.add(Duration(days: index)),
      growable: false,
    );
  }

  static String dueLabel(DateTime date) {
    final DateTime today = dateOnly(AppClock.now);
    final DateTime dueDate = dateOnly(date);
    final int difference = dueDate.difference(today).inDays;
    return switch (difference) {
      < 0 => 'Due on ${fullDate(date)}',
      0 => 'Due today',
      1 => 'Due tomorrow',
      _ => 'Due in $difference days',
    };
  }
}

class _ReminderTokens {
  const _ReminderTokens._();

  static const Color screenBackground = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF171638);
  static const Color appBarIcon = Color(0xFF1F2937);
  static const Color textStrong = Color(0xFF111827);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF6B7280);
  static const Color textInactive = Color(0xFF9CA3AF);
  static const Color labelStrong = Color(0xFF283154);
  static const Color amountStrong = Color(0xFF202124);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFFDC2626);
  static const Color dangerBorder = Color(0xFFFCA5A5);
  static const Color success = Color(0xFF16A34A);
  static const Color successAccent = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color today = Color(0xFFFACC15);
  static const Color blue = Color(0xFF2563EB);
  static const Color iconBlue = Color(0xFF60A5FA);
  static const Color border = Color(0xFFE5E7EB);
  static const Color inputBorder = Color(0xFF9CA3AF);
  static const Color softPanel = Color(0xFFF3F4F6);
  static const Color alertPanel = Color(0xFFE8EEF7);
  static const Color alertIcon = Color(0xFF293154);
  static const Color recurringSoft = Color(0xFFEFFCF8);
  static const Color recurringBorder = Color(0xFFA7F3D0);
  static const Color recurringText = Color(0xFF0F766E);

  static const double cardRadius = 4;
  static const double controlRadius = 3;
  static const double dialogRadius = 8;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(16, 10, 16, 20);
  static const EdgeInsets createPagePadding = EdgeInsets.fromLTRB(
    16,
    18,
    16,
    24,
  );
  static const EdgeInsets cardTilePadding = EdgeInsets.fromLTRB(12, 8, 12, 8);

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
  static const TextStyle sectionLabel = TextStyle(
    color: textSubtle,
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.3,
  );
  static const TextStyle viewAllLabel = TextStyle(
    color: warning,
    fontSize: 10,
    fontWeight: FontWeight.w800,
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
  static const TextStyle cardTitle = TextStyle(
    color: textMuted,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle cardBody = TextStyle(
    color: textStrong,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle emptyLabel = TextStyle(
    color: textSubtle,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle sheetTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle amountLabel = TextStyle(
    color: labelStrong,
    fontSize: 13,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
  );
  static const TextStyle amountValue = TextStyle(
    color: amountStrong,
    fontSize: 30,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle detailDate = TextStyle(
    color: textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle payeeLabel = TextStyle(
    color: Color(0xFF374151),
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.6,
  );
  static const TextStyle payeeValue = TextStyle(
    color: textStrong,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle alertTitle = TextStyle(
    color: textStrong,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle alertBody = TextStyle(
    color: textSubtle,
    fontSize: 11,
    fontWeight: FontWeight.w500,
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

const List<String> _categories = <String>[
  'Utilities',
  'Insurance',
  'Loan',
  'Rent',
  'Fuel',
  'Equipment',
  'Payroll',
  'Other',
];

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
