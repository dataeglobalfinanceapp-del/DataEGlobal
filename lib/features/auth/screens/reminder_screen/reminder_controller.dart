part of 'reminder_screen.dart';

class _ReminderController extends ChangeNotifier {
  bool _isDisposed = false;
  bool _isLoading = true;
  DateTime _visibleMonth = _ReminderDateUtils.monthStart(AppClock.now);
  List<ReminderRecord> _reminders = const <ReminderRecord>[];

  _ReminderViewState _state = _ReminderViewState.initial(
    _ReminderDateUtils.monthStart(AppClock.now),
  );

  _ReminderViewState get state => _state;

  Future<void> loadReminders({bool showLoading = true}) async {
    if (showLoading) {
      _setLoading(true);
    }

    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();
    if (_isDisposed) return;

    _reminders = List<ReminderRecord>.unmodifiable(reminders);
    _isLoading = false;
    _rebuildState();
    _notify();
  }

  void changeMonth(int delta) {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    _rebuildState();
    _notify();
  }

  List<ReminderRecord> remindersForDate(DateTime date) {
    return _state.remindersByDate[_ReminderDateUtils.dateKey(date)] ??
        const <ReminderRecord>[];
  }

  Future<void> updateAmount(
    ReminderRecord record,
    _AmountEditResult result,
  ) async {
    await RecurringExpenseReminderService.updateReminderAmount(
      reminderId: record.id,
      amount: result.amount,
      scope: result.applyToSeries
          ? ReminderEditScope.series
          : ReminderEditScope.single,
    );
    if (_isDisposed) return;
    await loadReminders(showLoading: false);
  }

  Future<bool> deleteReminder(
    ReminderRecord record,
    ReminderDeleteScope scope,
  ) async {
    final bool deleted = await RecurringExpenseReminderService.deleteReminder(
      reminderId: record.id,
      scope: scope,
    );
    if (_isDisposed) return deleted;
    await loadReminders(showLoading: false);
    return deleted;
  }

  Future<bool> markFinished(ReminderRecord record) async {
    final bool finished = await ReminderService.markFinished(record.id);
    if (_isDisposed) return finished;
    await loadReminders(showLoading: false);
    return finished;
  }

  Future<void> postpone(ReminderRecord record) async {
    await ReminderService.postpone(record.id);
    if (_isDisposed) return;
    await loadReminders(showLoading: false);
  }

  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;

    _isLoading = isLoading;
    _rebuildState();
    _notify();
  }

  void _rebuildState() {
    final Map<String, List<ReminderRecord>> remindersByDate =
        _ReminderDataMapper.remindersByDate(_reminders);
    final List<ReminderRecord> monthReminders =
        _ReminderDataMapper.monthReminders(_reminders, _visibleMonth);
    final List<_CalendarDayModel> calendarDays =
        _ReminderDataMapper.calendarDays(
          visibleMonth: _visibleMonth,
          remindersByDate: remindersByDate,
        );
    final List<_ReminderListEntry> entries = _ReminderDataMapper.listEntries(
      monthReminders,
    );

    _state = _ReminderViewState(
      isLoading: _isLoading,
      visibleMonth: _visibleMonth,
      monthReminders: monthReminders,
      calendarDays: calendarDays,
      entries: entries,
      remindersByDate: remindersByDate,
    );
  }

  void _notify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class _ReminderDataMapper {
  const _ReminderDataMapper._();

  static Map<String, List<ReminderRecord>> remindersByDate(
    List<ReminderRecord> reminders,
  ) {
    final Map<String, List<ReminderRecord>> buckets =
        <String, List<ReminderRecord>>{};

    for (final ReminderRecord record in reminders) {
      final String key = _ReminderDateUtils.dateKey(record.date);
      buckets.putIfAbsent(key, () => <ReminderRecord>[]).add(record);
    }

    final Map<String, List<ReminderRecord>> result =
        <String, List<ReminderRecord>>{};
    for (final MapEntry<String, List<ReminderRecord>> entry
        in buckets.entries) {
      entry.value.sort(
        (ReminderRecord a, ReminderRecord b) => a.date.compareTo(b.date),
      );
      result[entry.key] = List<ReminderRecord>.unmodifiable(entry.value);
    }

    return Map<String, List<ReminderRecord>>.unmodifiable(result);
  }

  static List<ReminderRecord> monthReminders(
    List<ReminderRecord> reminders,
    DateTime visibleMonth,
  ) {
    final List<ReminderRecord> records = reminders
        .where(
          (ReminderRecord record) =>
              record.date.year == visibleMonth.year &&
              record.date.month == visibleMonth.month,
        )
        .toList(growable: false);
    records.sort(
      (ReminderRecord a, ReminderRecord b) => a.date.compareTo(b.date),
    );
    return List<ReminderRecord>.unmodifiable(records);
  }

  static List<_CalendarDayModel> calendarDays({
    required DateTime visibleMonth,
    required Map<String, List<ReminderRecord>> remindersByDate,
  }) {
    final DateTime today = _ReminderDateUtils.dateOnly(AppClock.now);
    return _ReminderDateUtils.calendarDates(visibleMonth)
        .map((DateTime date) {
          final List<ReminderRecord> reminders =
              remindersByDate[_ReminderDateUtils.dateKey(date)] ??
              const <ReminderRecord>[];
          return _CalendarDayModel(
            date: date,
            isInVisibleMonth: date.month == visibleMonth.month,
            isToday: _ReminderDateUtils.isSameDate(date, today),
            reminders: reminders,
          );
        })
        .toList(growable: false);
  }

  static List<_ReminderListEntry> listEntries(
    List<ReminderRecord> monthReminders,
  ) {
    if (monthReminders.isEmpty) {
      return const <_ReminderListEntry>[_EmptyReminderEntry()];
    }

    return List<_ReminderListEntry>.unmodifiable(
      monthReminders.map<_ReminderListEntry>(_ReminderRecordEntry.new),
    );
  }
}

class _CreateReminderController extends ChangeNotifier {
  final DateTime initialDate;
  final List<_ReminderFormData> _forms = <_ReminderFormData>[];
  bool _isDisposed = false;
  bool _isSaving = false;

  _CreateReminderController({required this.initialDate}) {
    _forms.add(_ReminderFormData(date: initialDate));
  }

  List<_ReminderFormData> get forms =>
      List<_ReminderFormData>.unmodifiable(_forms);

  bool get isSaving => _isSaving;

  Future<bool> save() async {
    final List<ReminderDraft> drafts = _forms
        .map<ReminderDraft>((_ReminderFormData form) => form.toDraft())
        .where((ReminderDraft draft) => draft.amount > 0)
        .toList(growable: false);

    if (drafts.isEmpty) {
      return false;
    }

    _setSaving(true);
    try {
      await RecurringExpenseReminderService.saveReminderDrafts(drafts);
      return true;
    } finally {
      _setSaving(false);
    }
  }

  void addReminder() {
    _forms.add(_ReminderFormData(date: initialDate));
    _notify();
  }

  void removeReminder(_ReminderFormData form) {
    if (_forms.length == 1) return;

    final bool removed = _forms.remove(form);
    if (!removed) return;

    form.dispose();
    _notify();
  }

  void setFormDate(_ReminderFormData form, DateTime date) {
    form.date = date;
    _notify();
  }

  void setCategory(_ReminderFormData form, String category) {
    form.category = category;
    _notify();
  }

  void setReminderCount(_ReminderFormData form, String reminderCount) {
    form.reminderCount = reminderCount;
    _notify();
  }

  void _setSaving(bool isSaving) {
    if (_isSaving == isSaving) return;

    _isSaving = isSaving;
    _notify();
  }

  void _notify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final _ReminderFormData form in _forms) {
      form.dispose();
    }
    super.dispose();
  }
}
