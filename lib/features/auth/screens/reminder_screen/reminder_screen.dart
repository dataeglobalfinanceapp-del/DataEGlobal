import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../services/money_formatter.dart';
import '../../../../services/reminder_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<ReminderRecord> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final reminders = await ReminderService.loadReminders();
    if (!mounted) return;
    setState(() {
      _reminders = reminders;
      _isLoading = false;
    });
  }

  List<ReminderRecord> get _monthReminders {
    return _reminders
        .where(
          (record) =>
              record.date.year == _visibleMonth.year &&
              record.date.month == _visibleMonth.month,
        )
        .toList();
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  Future<void> _openCreate({DateTime? initialDate}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CreateReminderScreen(initialDate: initialDate ?? DateTime.now()),
      ),
    );
    if (!mounted) return;
    await _loadReminders();
  }

  Future<void> _handleDateTap(DateTime date) async {
    final reminders = _remindersForDate(date);
    if (reminders.isEmpty) {
      await _openCreate(initialDate: date);
      return;
    }

    if (reminders.length == 1) {
      await _showReminderDialog(reminders.first);
      return;
    }

    final selected = await showModalBottomSheet<ReminderRecord>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _formatFullDate(date),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...reminders.map(
              (record) => ListTile(
                title: Text(record.payee),
                subtitle: Text(record.category),
                trailing: Text(
                  formatMoney(record.amount),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onTap: () => Navigator.pop(context, record),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Color(0xFF2563EB)),
              title: const Text('Add another reminder'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (selected == null) {
      await _openCreate(initialDate: date);
    } else {
      await _showReminderDialog(selected);
    }
  }

  Future<void> _showReminderDialog(ReminderRecord record) async {
    var alertEnabled = record.alertEnabled;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DueBadge(record: record),
                    const SizedBox(height: 28),
                    const Text(
                      'AMOUNT DUE',
                      style: TextStyle(
                        color: Color(0xFF283154),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatMoney(record.amount),
                        style: const TextStyle(
                          color: Color(0xFF202124),
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatFullDate(record.date),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 20,
                          color: Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'PAYEE',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            record.payee,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EEF7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            color: Color(0xFF293154),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alert Notifications',
                                style: TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Receive reminders for this event',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: alertEnabled,
                          activeThumbColor: const Color(0xFF171638),
                          onChanged: (value) async {
                            await ReminderService.updateAlert(record.id, value);
                            setDialogState(() => alertEnabled = value);
                            await _loadReminders();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F4F6),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            onPressed: () async {
                              await ReminderService.postpone(record.id);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              await _loadReminders();
                            },
                            child: const Text(
                              'Postpone',
                              style: TextStyle(color: Color(0xFF111827)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF171638),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<ReminderRecord> _remindersForDate(DateTime date) {
    return _reminders
        .where(
          (record) =>
              record.date.year == date.year &&
              record.date.month == date.month &&
              record.date.day == date.day,
        )
        .toList();
  }

  bool _hasReminder(DateTime date) => _remindersForDate(date).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reminder',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1F2937)),
            onPressed: () => _openCreate(initialDate: DateTime.now()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReminders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  _MonthHeader(
                    visibleMonth: _visibleMonth,
                    onPrev: () => _changeMonth(-1),
                    onNext: () => _changeMonth(1),
                  ),
                  const SizedBox(height: 10),
                  _CalendarGrid(
                    visibleMonth: _visibleMonth,
                    remindersForDate: _remindersForDate,
                    hasReminder: _hasReminder,
                    onTapDate: _handleDateTap,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'PAYMENT OBLIGATIONS',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'View all',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_monthReminders.isEmpty)
                    const _EmptyReminderList()
                  else
                    ..._monthReminders.map(
                      (record) => _ReminderCard(
                        record: record,
                        onTap: () => _showReminderDialog(record),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class CreateReminderScreen extends StatefulWidget {
  final DateTime initialDate;

  const CreateReminderScreen({super.key, required this.initialDate});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final List<_ReminderFormData> _forms = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _forms.add(_ReminderFormData(date: widget.initialDate));
  }

  @override
  void dispose() {
    for (final form in _forms) {
      form.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final drafts = _forms
        .map(
          (form) => ReminderDraft(
            date: form.date,
            category: form.category,
            amount: parseMoney(form.amountController.text),
            reminderCount: form.reminderCount,
            payee: form.category,
          ),
        )
        .where((draft) => draft.amount > 0)
        .toList();

    if (drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one reminder amount.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ReminderService.saveReminders(drafts);
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addReminder() {
    setState(() => _forms.add(_ReminderFormData(date: widget.initialDate)));
  }

  void _removeReminder(int index) {
    if (_forms.length == 1) return;
    final form = _forms.removeAt(index);
    form.dispose();
    setState(() {});
  }

  Future<void> _pickDate(_ReminderFormData form) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: form.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => form.date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Reminder',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, color: Colors.black87),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          ...List.generate(
            _forms.length,
            (index) => _ReminderForm(
              form: _forms[index],
              canRemove: _forms.length > 1,
              onPickDate: () => _pickDate(_forms[index]),
              onRemove: () => _removeReminder(index),
              onChanged: () => setState(() {}),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _addReminder,
            icon: const Icon(Icons.note_add_outlined, color: Color(0xFF60A5FA)),
            label: const Text(
              'Add more reminder',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              side: const BorderSide(color: Color(0xFF9CA3AF)),
            ),
          ),
        ],
      ),
    );
  }
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

  void dispose() {
    amountController.dispose();
  }
}

class _ReminderForm extends StatelessWidget {
  final _ReminderFormData form;
  final bool canRemove;
  final VoidCallback onPickDate;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ReminderForm({
    required this.form,
    required this.canRemove,
    required this.onPickDate,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          if (canRemove)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FormFieldShell(
                  label: 'DATE',
                  isRequired: true,
                  child: InkWell(
                    onTap: onPickDate,
                    child: _InputLikeBox(
                      child: Row(
                        children: [
                          Expanded(child: Text(_formatFullDate(form.date))),
                          const Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: Color(0xFF60A5FA),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _FormFieldShell(
                  label: 'CATEGORY',
                  isRequired: true,
                  child: _InputLikeBox(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: form.category,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.grid_view,
                          size: 18,
                          color: Color(0xFF60A5FA),
                        ),
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          form.category = value;
                          onChanged();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FormFieldShell(
                  label: 'AMOUNT',
                  isRequired: true,
                  child: _InputLikeBox(
                    child: TextField(
                      controller: form.amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,12},?\d{0,3}\.?\d{0,2}'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'e.g: \$120.00',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _FormFieldShell(
                  label: 'REMINDER COUNT',
                  child: _InputLikeBox(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: form.reminderCount,
                        isExpanded: true,
                        items: _reminderCounts
                            .map(
                              (count) => DropdownMenuItem(
                                value: count,
                                child: Text(count),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          form.reminderCount = value;
                          onChanged();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormFieldShell extends StatelessWidget {
  final String label;
  final bool isRequired;
  final Widget child;

  const _FormFieldShell({
    required this.label,
    required this.child,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xFF283154),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InputLikeBox extends StatelessWidget {
  final Widget child;

  const _InputLikeBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime visibleMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.visibleMonth,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, size: 20),
        ),
        Text(
          '${_monthNames[visibleMonth.month]} ${visibleMonth.year}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime visibleMonth;
  final List<ReminderRecord> Function(DateTime date) remindersForDate;
  final bool Function(DateTime date) hasReminder;
  final ValueChanged<DateTime> onTapDate;

  const _CalendarGrid({
    required this.visibleMonth,
    required this.remindersForDate,
    required this.hasReminder,
    required this.onTapDate,
  });

  @override
  Widget build(BuildContext context) {
    final days = _calendarDays(visibleMonth);
    const weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: weekdays
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              final inMonth = date.month == visibleMonth.month;
              final today = _isSameDate(date, DateTime.now());
              final reminders = remindersForDate(date);
              final hasItems = reminders.isNotEmpty;
              final isOverdue =
                  hasItems && date.isBefore(_dateOnly(DateTime.now()));
              final background = hasItems
                  ? isOverdue
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF16A34A)
                  : today
                  ? const Color(0xFFFACC15)
                  : Colors.transparent;
              final foreground = hasItems || today
                  ? Colors.white
                  : inMonth
                  ? const Color(0xFF111827)
                  : const Color(0xFF9CA3AF);

              return InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => onTapDate(date),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 10,
                        fontWeight: hasItems || today
                            ? FontWeight.w900
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<DateTime> _calendarDays(DateTime month) {
    final first = DateTime(month.year, month.month);
    final start = first.subtract(Duration(days: first.weekday % 7));
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderRecord record;
  final VoidCallback onTap;

  const _ReminderCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(record.date);
    final isOverdue = status == _ReminderStatus.overdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: isOverdue
                ? const Color(0xFFEF4444)
                : const Color(0xFF22C55E),
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        onTap: onTap,
        title: Text(
          _formatFullDate(record.date),
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            record.payee,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoney(record.amount),
              style: TextStyle(
                color: isOverdue
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFF59E0B),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  color: isOverdue
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF22C55E),
                  size: 7,
                ),
                const SizedBox(width: 4),
                Text(
                  isOverdue ? 'Overdue' : 'Upcoming',
                  style: TextStyle(
                    color: isOverdue
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF16A34A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReminderList extends StatelessWidget {
  const _EmptyReminderList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_none, color: Color(0xFF9CA3AF), size: 32),
          SizedBox(height: 8),
          Text(
            'Tap a date to create a reminder.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  final ReminderRecord record;

  const _DueBadge({required this.record});

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final dueDate = _dateOnly(record.date);
    final difference = dueDate.difference(today).inDays;
    final label = switch (difference) {
      < 0 => 'Overdue by ${difference.abs()} day${difference == -1 ? '' : 's'}',
      0 => 'Due today',
      1 => 'Due tomorrow',
      _ => 'Due in $difference days',
    };
    final isOverdue = difference < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isOverdue ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFFFACC15),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFFD97706),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _ReminderStatus { upcoming, overdue }

_ReminderStatus _statusFor(DateTime date) {
  return _dateOnly(date).isBefore(_dateOnly(DateTime.now()))
      ? _ReminderStatus.overdue
      : _ReminderStatus.upcoming;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatFullDate(DateTime date) {
  return '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}/${date.year}';
}

const _categories = [
  'Utilities',
  'Insurance',
  'Loan',
  'Rent',
  'Fuel',
  'Equipment',
  'Payroll',
  'Other',
];

const _reminderCounts = [
  'Monthly',
  'Just one',
  'Weekly',
  'Quarterly',
  'Yearly',
];

const _monthNames = [
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
