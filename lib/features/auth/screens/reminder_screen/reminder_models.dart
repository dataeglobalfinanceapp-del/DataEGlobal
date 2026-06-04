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
  final bool isOverdue;
  final List<ReminderRecord> reminders;

  const _CalendarDayModel({
    required this.date,
    required this.isInVisibleMonth,
    required this.isToday,
    required this.isOverdue,
    required this.reminders,
  });

  bool get hasReminders => reminders.isNotEmpty;
}

enum _ReminderDetailAction { editAmount, delete, postpone }

enum _ReminderStatus { upcoming, overdue }

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

  static _ReminderStatus statusFor(DateTime date) {
    return dateOnly(date).isBefore(dateOnly(AppClock.now))
        ? _ReminderStatus.overdue
        : _ReminderStatus.upcoming;
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
      < 0 => 'Overdue by ${difference.abs()} day${difference == -1 ? '' : 's'}',
      0 => 'Due today',
      1 => 'Due tomorrow',
      _ => 'Due in $difference days',
    };
  }
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
