part of 'reminder_screen.dart';

class _ReminderController extends ChangeNotifier {
  bool _isDisposed = false;
  bool _isLoading = true;
  _ReminderViewMode _viewMode = _ReminderViewMode.month;
  DateTime _visibleMonth = _ReminderDateUtils.monthStart(AppClock.now);
  DateTime _visibleWeekStart = _ReminderDateUtils.weekStart(AppClock.now);
  List<ReminderRecord> _reminders = const <ReminderRecord>[];
  List<DepositRecord> _deposits = const <DepositRecord>[];
  List<ExpenseRecord> _expenses = const <ExpenseRecord>[];

  _ReminderViewState _state = _ReminderViewState.initial(
    _ReminderDateUtils.monthStart(AppClock.now),
    _ReminderDateUtils.weekStart(AppClock.now),
  );

  _ReminderViewState get state => _state;

  Future<void> loadReminders({bool showLoading = true}) async {
    if (showLoading) {
      _setLoading(true);
    }

    final List<ReminderRecord> reminders =
        await ReminderService.loadReminders();
    final List<DepositRecord> deposits = await LiabilityService.loadDeposits();
    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();
    if (_isDisposed) return;

    _reminders = List<ReminderRecord>.unmodifiable(reminders);
    _deposits = List<DepositRecord>.unmodifiable(deposits);
    _expenses = List<ExpenseRecord>.unmodifiable(expenses);
    _isLoading = false;
    _rebuildState();
    _notify();
  }

  void setViewMode(_ReminderViewMode mode) {
    if (_viewMode == mode) return;

    _viewMode = mode;
    _rebuildState();
    _notify();
  }

  void showMonthView() {
    setViewMode(_ReminderViewMode.month);
  }

  void changePeriod(int delta) {
    if (_viewMode == _ReminderViewMode.week) {
      _visibleWeekStart = _visibleWeekStart.add(Duration(days: delta * 7));
      _visibleMonth = _ReminderDateUtils.monthStart(_visibleWeekStart);
    } else {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _visibleWeekStart = _ReminderDateUtils.weekStart(_visibleMonth);
    }
    _rebuildState();
    _notify();
  }

  List<ReminderRecord> remindersForDate(DateTime date) {
    return _state.remindersByDate[_ReminderDateUtils.dateKey(date)] ??
        const <ReminderRecord>[];
  }

  Future<bool> updateAmount(
    ReminderRecord record,
    _AmountEditResult result,
  ) async {
    final bool updated =
        await RecurringExpenseReminderService.updateReminderAmount(
          reminderId: record.id,
          amount: result.amount,
          scope: result.applyToSeries
              ? ReminderEditScope.series
              : ReminderEditScope.single,
        );
    if (_isDisposed) return updated;
    await loadReminders(showLoading: false);
    return updated;
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

  void _setLoading(bool isLoading) {
    if (_isLoading == isLoading) return;

    _isLoading = isLoading;
    _rebuildState();
    _notify();
  }

  void _rebuildState() {
    final DateTime calendarMonth = _viewMode == _ReminderViewMode.week
        ? _ReminderDateUtils.monthStart(_visibleWeekStart)
        : _visibleMonth;
    final DateTime periodStart = _viewMode == _ReminderViewMode.week
        ? _visibleWeekStart
        : _visibleMonth;
    final DateTime periodEndExclusive = _viewMode == _ReminderViewMode.week
        ? _visibleWeekStart.add(const Duration(days: 7))
        : DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    final Map<String, List<ReminderRecord>> remindersByDate =
        _ReminderDataMapper.remindersByDate(_reminders);
    final List<ReminderRecord> periodReminders =
        _ReminderDataMapper.periodReminders(
          _reminders,
          start: periodStart,
          endExclusive: periodEndExclusive,
        );
    final List<_CalendarDayModel> calendarDays =
        _ReminderDataMapper.calendarDays(
          dates: _viewMode == _ReminderViewMode.week
              ? _ReminderDateUtils.weekDates(_visibleWeekStart)
              : _ReminderDateUtils.calendarDates(calendarMonth),
          visibleMonth: calendarMonth,
          selectedStart: periodStart,
          selectedEndExclusive: periodEndExclusive,
          remindersByDate: remindersByDate,
        );
    final List<_ReminderListEntry> entries = _ReminderDataMapper.listEntries(
      periodReminders,
      year: periodStart.year,
    );

    _state = _ReminderViewState(
      isLoading: _isLoading,
      viewMode: _viewMode,
      visibleMonth: calendarMonth,
      visibleWeekStart: _visibleWeekStart,
      periodStart: periodStart,
      periodEndExclusive: periodEndExclusive,
      periodReminders: periodReminders,
      calendarDays: calendarDays,
      entries: entries,
      remindersByDate: remindersByDate,
      availableFunds: _ReminderDataMapper.availableFunds(
        deposits: _deposits,
        expenses: _expenses,
      ),
      spentInPeriod: _ReminderDataMapper.spentInPeriod(
        reminders: periodReminders,
      ),
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

  static List<ReminderRecord> periodReminders(
    List<ReminderRecord> reminders, {
    required DateTime start,
    required DateTime endExclusive,
  }) {
    final List<ReminderRecord> records = reminders
        .where(
          (ReminderRecord record) =>
              !record.date.isBefore(start) &&
              record.date.isBefore(endExclusive),
        )
        .toList(growable: false);
    records.sort(
      (ReminderRecord a, ReminderRecord b) => a.date.compareTo(b.date),
    );
    return List<ReminderRecord>.unmodifiable(records);
  }

  static List<_CalendarDayModel> calendarDays({
    required List<DateTime> dates,
    required DateTime visibleMonth,
    required DateTime selectedStart,
    required DateTime selectedEndExclusive,
    required Map<String, List<ReminderRecord>> remindersByDate,
  }) {
    final DateTime today = _ReminderDateUtils.dateOnly(AppClock.now);
    return dates
        .map((DateTime date) {
          final List<ReminderRecord> reminders =
              remindersByDate[_ReminderDateUtils.dateKey(date)] ??
              const <ReminderRecord>[];
          return _CalendarDayModel(
            date: date,
            isInVisibleMonth: date.month == visibleMonth.month,
            isInSelectedPeriod:
                !date.isBefore(selectedStart) &&
                date.isBefore(selectedEndExclusive),
            isToday: _ReminderDateUtils.isSameDate(date, today),
            reminders: reminders,
          );
        })
        .toList(growable: false);
  }

  static List<_ReminderListEntry> listEntries(
    List<ReminderRecord> reminders, {
    required int year,
  }) {
    if (reminders.isEmpty) {
      return const <_ReminderListEntry>[_EmptyReminderEntry()];
    }

    return List<_ReminderListEntry>.unmodifiable(
      reminders.map<_ReminderListEntry>(
        (ReminderRecord record) => _ReminderRecordEntry(
          record: record,
          remainingBalanceThisYear: ReminderService.remainingBalanceThisYear(
            record,
            year: year,
          ),
        ),
      ),
    );
  }

  static double availableFunds({
    required List<DepositRecord> deposits,
    required List<ExpenseRecord> expenses,
  }) {
    final double totalDeposits = deposits.fold<double>(
      0,
      (double total, DepositRecord record) => total + record.totalAmount,
    );
    final double totalExpenses = expenses.fold<double>(
      0,
      (double total, ExpenseRecord record) => total + record.totalAmount,
    );
    return totalDeposits - totalExpenses;
  }

  static double spentInPeriod({required List<ReminderRecord> reminders}) {
    return reminders.fold<double>(
      0,
      (double total, ReminderRecord record) => total + record.amount,
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
