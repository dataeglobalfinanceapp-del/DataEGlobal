import 'app_clock.dart';
import 'liability_service.dart';
import 'recurrence_schedule.dart';
import 'reminder_service.dart';

class RecurringExpenseReminderService {
  RecurringExpenseReminderService._();

  static int _idCounter = 0;

  static Future<void> saveRecurringExpenseWithReminder({
    required String checkNumber,
    required double totalAmount,
    required DateTime transactionDate,
    required DateTime startDate,
    required String category,
    required String payee,
    required bool isManual,
    required String frequency,
  }) async {
    final String recurringId = _newRecurringId();
    await LiabilityService.saveExpense(
      checkNumber: checkNumber,
      totalAmount: totalAmount,
      transactionDate: transactionDate,
      category: category,
      payee: payee,
      isManual: isManual,
      isRecurringMonthly: true,
      recurringStartDate: startDate,
      recurringFrequency: frequency,
      recurringSeriesId: recurringId,
    );
    await ReminderService.saveReminders(<ReminderDraft>[
      ReminderDraft(
        date: startDate,
        category: category,
        amount: totalAmount,
        reminderCount: frequency,
        payee: payee,
        recurringSeriesId: recurringId,
      ),
    ]);
  }

  static Future<void> saveReminderDrafts(List<ReminderDraft> drafts) async {
    final List<ReminderDraft> oneTimeDrafts = <ReminderDraft>[];

    for (final ReminderDraft draft in drafts) {
      if (!RecurrenceSchedule.isRecurringFrequency(draft.reminderCount)) {
        oneTimeDrafts.add(draft);
        continue;
      }

      await saveRecurringExpenseWithReminder(
        checkNumber: '',
        totalAmount: draft.amount,
        transactionDate: draft.date,
        startDate: draft.date,
        category: draft.category,
        payee: draft.payee,
        isManual: true,
        frequency: draft.reminderCount,
      );
    }

    if (oneTimeDrafts.isNotEmpty) {
      await ReminderService.saveReminders(oneTimeDrafts);
    }
  }

  static Future<bool> updateReminderAmount({
    required String reminderId,
    required double amount,
    ReminderEditScope scope = ReminderEditScope.single,
  }) async {
    if (amount <= 0) return false;

    final ReminderRecord? reminder = await _reminderById(reminderId);
    if (reminder == null) return false;

    await ReminderService.updateAmount(reminderId, amount, scope: scope);
    if (!reminder.isRecurring) return true;

    if (scope == ReminderEditScope.series) {
      await LiabilityService.updateRecurringExpenseAmount(
        recurringSeriesId: reminder.recurringSeriesId,
        amount: amount,
        fromDate: reminder.date,
      );
      return true;
    }

    await LiabilityService.updateRecurringExpenseAmount(
      recurringSeriesId: reminder.recurringSeriesId,
      amount: amount,
      occurrenceDate: reminder.date,
    );
    return true;
  }

  static Future<bool> deleteReminder({
    required String reminderId,
    ReminderDeleteScope scope = ReminderDeleteScope.single,
  }) async {
    final ReminderRecord? reminder = await _reminderById(reminderId);
    if (reminder == null) return false;
    if (!reminder.isRecurring) {
      return ReminderService.deleteReminder(reminderId, scope: scope);
    }

    if (scope == ReminderDeleteScope.single) {
      return ReminderService.deleteReminder(reminderId, scope: scope);
    }

    await LiabilityService.deleteFutureRecurringExpenses(
      recurringSeriesId: reminder.recurringSeriesId,
      fromDate: AppClock.now,
    );
    return ReminderService.deleteReminder(
      reminderId,
      scope: ReminderDeleteScope.series,
    );
  }

  static Future<ReminderRecord?> _reminderById(String reminderId) async {
    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();
    for (final ReminderRecord reminder in reminders) {
      if (reminder.id == reminderId) return reminder;
    }
    return null;
  }

  static String _newRecurringId() {
    return 'recurring-${AppClock.now.microsecondsSinceEpoch}-${_idCounter++}';
  }
}
