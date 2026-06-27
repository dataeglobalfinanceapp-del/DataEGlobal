import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/services/money_formatter.dart';
import 'package:savetep/services/recurring_expense_reminder_service.dart';
import 'package:savetep/services/reminder_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

part 'reminder_controller.dart';
part 'reminder_models.dart';
part 'reminder_widgets.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late final _ReminderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _ReminderController()..loadReminders();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCreate({DateTime? initialDate}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return CreateReminderScreen(initialDate: initialDate ?? AppClock.now);
        },
      ),
    );
    if (!mounted) return;
    await _controller.loadReminders();
  }

  Future<void> _editReminderAmount(ReminderRecord record) async {
    final _AmountEditResult? result = await showDialog<_AmountEditResult>(
      context: context,
      builder: (BuildContext context) {
        return _AmountEditDialog(record: record);
      },
    );
    if (result == null) return;

    final bool updated = await _controller.updateAmount(record, result);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !updated
              ? 'Could not update that reminder.'
              : result.applyToSeries
              ? 'Recurring reminder amounts updated.'
              : 'Reminder amount updated.',
        ),
      ),
    );
  }

  Future<void> _deleteReminder(ReminderRecord record) async {
    final ReminderDeleteScope? scope = await showDialog<ReminderDeleteScope>(
      context: context,
      builder: (BuildContext context) {
        return record.isRecurring
            ? const _DeleteRecurringReminderDialog()
            : const _DeleteReminderDialog();
      },
    );
    if (scope == null) return;

    final bool deleted = await _controller.deleteReminder(record, scope);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? scope == ReminderDeleteScope.series
                    ? 'Recurring reminder series deleted.'
                    : 'Reminder deleted.'
              : 'Could not find that reminder.',
        ),
      ),
    );
  }

  Future<void> _markReminderFinished(ReminderRecord record) async {
    final bool finished = await _controller.markFinished(record);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          finished
              ? 'Reminder marked as finished.'
              : 'Could not find that reminder.',
        ),
      ),
    );
  }

  Future<void> _handleDateTap(DateTime date) async {
    final List<ReminderRecord> reminders = _controller.remindersForDate(date);
    if (reminders.isEmpty) {
      await _openCreate(initialDate: date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ReminderTokens.screenBackground,
      appBar: AppBar(
        backgroundColor: _ReminderTokens.surface,
        elevation: 0,
        title: const Text('Reminder', style: _ReminderTokens.appBarTitle),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add, color: _ReminderTokens.appBarIcon),
            onPressed: () => _openCreate(initialDate: AppClock.now),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentItem: AppBottomNavItem.calendar,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? child) {
          final _ReminderViewState state = _controller.state;

          return RefreshIndicator(
            onRefresh: _controller.loadReminders,
            child: state.isLoading
                ? const _LoadingReminderList()
                : _ReminderList(
                    state: state,
                    onPreviousPeriod: () => _controller.changePeriod(-1),
                    onNextPeriod: () => _controller.changePeriod(1),
                    onViewModeChanged: _controller.setViewMode,
                    onViewAll: _controller.showMonthView,
                    onTapDate: _handleDateTap,
                    onEditAmount: _editReminderAmount,
                    onDelete: _deleteReminder,
                    onMarkFinished: _markReminderFinished,
                  ),
          );
        },
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
  late final _CreateReminderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _CreateReminderController(initialDate: widget.initialDate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final bool saved = await _controller.save();
    if (!mounted) return;

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one reminder amount.')),
      );
      return;
    }

    Navigator.pop(context, true);
  }

  Future<void> _pickDate(_ReminderFormData form) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: form.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;

    _controller.setFormDate(form, picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          backgroundColor: _ReminderTokens.screenBackground,
          appBar: AppBar(
            backgroundColor: _ReminderTokens.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Create Reminder',
              style: _ReminderTokens.appBarTitle,
            ),
            centerTitle: true,
            actions: <Widget>[
              IconButton(
                icon: _controller.isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, color: Colors.black87),
                onPressed: _controller.isSaving ? null : _save,
              ),
            ],
          ),
          body: _CreateReminderList(
            forms: _controller.forms,
            onPickDate: _pickDate,
            onRemove: _controller.removeReminder,
            onAdd: _controller.addReminder,
            onCategoryChanged: _controller.setCategory,
            onReminderCountChanged: _controller.setReminderCount,
          ),
        );
      },
    );
  }
}
