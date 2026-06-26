part of 'reminder_screen.dart';

final TextInputFormatter _moneyInputFormatter =
    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,12},?\d{0,3}\.?\d{0,2}'));

class _LoadingReminderList extends StatelessWidget {
  const _LoadingReminderList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const <Widget>[
        SizedBox(
          height: 360,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _ReminderList extends StatelessWidget {
  final _ReminderViewState state;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;
  final ValueChanged<_ReminderViewMode> onViewModeChanged;
  final VoidCallback onViewAll;
  final ValueChanged<DateTime> onTapDate;
  final ValueChanged<ReminderRecord> onEditAmount;
  final ValueChanged<ReminderRecord> onDelete;
  final ValueChanged<ReminderRecord> onMarkFinished;

  const _ReminderList({
    required this.state,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.onViewModeChanged,
    required this.onViewAll,
    required this.onTapDate,
    required this.onEditAmount,
    required this.onDelete,
    required this.onMarkFinished,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: _ReminderTokens.pagePadding,
      scrollCacheExtent: const ScrollCacheExtent.pixels(900),
      itemCount: state.entries.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _ReminderHeader(
            state: state,
            onPreviousPeriod: onPreviousPeriod,
            onNextPeriod: onNextPeriod,
            onViewModeChanged: onViewModeChanged,
            onViewAll: onViewAll,
            onTapDate: onTapDate,
          );
        }

        final _ReminderListEntry entry = state.entries[index - 1];
        return switch (entry) {
          _ReminderRecordEntry(
            :final ReminderRecord record,
            :final double remainingBalanceThisYear,
          ) =>
            _ReminderCard(
              record: record,
              remainingBalanceThisYear: remainingBalanceThisYear,
              onEditAmount: () => onEditAmount(record),
              onDelete: () => onDelete(record),
              onMarkFinished: () => onMarkFinished(record),
            ),
          _EmptyReminderEntry() => const _EmptyReminderList(),
        };
      },
    );
  }
}

class _ReminderHeader extends StatelessWidget {
  final _ReminderViewState state;
  final VoidCallback onPreviousPeriod;
  final VoidCallback onNextPeriod;
  final ValueChanged<_ReminderViewMode> onViewModeChanged;
  final VoidCallback onViewAll;
  final ValueChanged<DateTime> onTapDate;

  const _ReminderHeader({
    required this.state,
    required this.onPreviousPeriod,
    required this.onNextPeriod,
    required this.onViewModeChanged,
    required this.onViewAll,
    required this.onTapDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _ReminderSummary(state: state),
        const SizedBox(height: 8),
        _PeriodRangeBar(label: state.rangeLabel),
        const SizedBox(height: 8),
        _ViewModeToolbar(
          selectedMode: state.viewMode,
          onModeChanged: onViewModeChanged,
          onPrev: onPreviousPeriod,
          onNext: onNextPeriod,
        ),
        const SizedBox(height: 8),
        _MonthHeader(visibleMonth: state.visibleMonth),
        const SizedBox(height: 5),
        _CalendarGrid(days: state.calendarDays, onTapDate: onTapDate),
        const SizedBox(height: 10),
        _ReminderSectionHeader(
          showViewAll: state.hasVisibleReminders,
          onViewAll: onViewAll,
        ),
      ],
    );
  }
}

class _ReminderSummary extends StatelessWidget {
  final _ReminderViewState state;

  const _ReminderSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
      decoration: BoxDecoration(
        color: _ReminderTokens.surface,
        borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
        boxShadow: _ReminderTokens.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _SummaryMetric(
              label: 'Available funds',
              amount: state.availableFunds,
              amountColor: _ReminderTokens.warning,
            ),
          ),
          Container(width: 1, height: 42, color: _ReminderTokens.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: _SummaryMetric(
                label: state.spentLabel,
                amount: state.spentInPeriod,
                amountColor: _ReminderTokens.success,
                alignRight: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final double amount;
  final Color amountColor;
  final bool alignRight;

  const _SummaryMetric({
    required this.label,
    required this.amount,
    required this.amountColor,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _ReminderTokens.summaryLabel),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            formatMoney(amount),
            style: _ReminderTokens.summaryAmount.copyWith(color: amountColor),
          ),
        ),
      ],
    );
  }
}

class _PeriodRangeBar extends StatelessWidget {
  final String label;

  const _PeriodRangeBar({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _ReminderTokens.surface,
        borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
        border: Border.all(color: _ReminderTokens.border),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ReminderTokens.textStrong,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.calendar_month,
            size: 17,
            color: _ReminderTokens.navy,
          ),
        ],
      ),
    );
  }
}

class _ViewModeToolbar extends StatelessWidget {
  final _ReminderViewMode selectedMode;
  final ValueChanged<_ReminderViewMode> onModeChanged;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _ViewModeToolbar({
    required this.selectedMode,
    required this.onModeChanged,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 34,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _ReminderTokens.surface,
              borderRadius: BorderRadius.circular(
                _ReminderTokens.controlRadius,
              ),
              border: Border.all(color: _ReminderTokens.border),
            ),
            child: Row(
              children: <Widget>[
                for (final _ReminderViewMode mode in _ReminderViewMode.values)
                  Expanded(
                    child: _ViewModeButton(
                      mode: mode,
                      isSelected: mode == selectedMode,
                      onPressed: () => onModeChanged(mode),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _PeriodIconButton(icon: Icons.chevron_left, onPressed: onPrev),
        const SizedBox(width: 6),
        _PeriodIconButton(icon: Icons.chevron_right, onPressed: onNext),
      ],
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final _ReminderViewMode mode;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ViewModeButton({
    required this.mode,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? _ReminderTokens.navy : Colors.transparent,
        foregroundColor: isSelected
            ? _ReminderTokens.warning
            : _ReminderTokens.textStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
        ),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        mode.label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PeriodIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _PeriodIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: _ReminderTokens.surface,
          foregroundColor: _ReminderTokens.textStrong,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
            side: const BorderSide(color: _ReminderTokens.border),
          ),
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class _ReminderSectionHeader extends StatelessWidget {
  final bool showViewAll;
  final VoidCallback onViewAll;

  const _ReminderSectionHeader({
    required this.showViewAll,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            'PAYMENT OBLIGATIONS',
            style: _ReminderTokens.sectionLabel,
          ),
        ),
        if (showViewAll)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 28),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: _ReminderTokens.warning,
            ),
            child: const Text(
              'View all',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime visibleMonth;

  const _MonthHeader({required this.visibleMonth});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_monthNames[visibleMonth.month]} ${visibleMonth.year}',
      style: _ReminderTokens.monthTitle,
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final List<_CalendarDayModel> days;
  final ValueChanged<DateTime> onTapDate;

  const _CalendarGrid({required this.days, required this.onTapDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: _ReminderTokens.surface,
        borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
        boxShadow: _ReminderTokens.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          const _WeekdayRow(),
          const SizedBox(height: 4),
          for (int row = 0; row < days.length ~/ 7; row += 1)
            Row(
              children: <Widget>[
                for (int column = 0; column < 7; column += 1)
                  Expanded(
                    child: _CalendarDayCell(
                      day: days[(row * 7) + column],
                      onTap: onTapDate,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(child: _WeekdayLabel('SUN')),
        Expanded(child: _WeekdayLabel('MON')),
        Expanded(child: _WeekdayLabel('TUE')),
        Expanded(child: _WeekdayLabel('WED')),
        Expanded(child: _WeekdayLabel('THU')),
        Expanded(child: _WeekdayLabel('FRI')),
        Expanded(child: _WeekdayLabel('SAT')),
      ],
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: _ReminderTokens.weekdayLabel,
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final _CalendarDayModel day;
  final ValueChanged<DateTime> onTap;

  const _CalendarDayCell({required this.day, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final _ReminderStatus? status = day.hasReminders
        ? _ReminderStatus.fromRecord(day.reminders.first)
        : null;
    final Color background = status != null
        ? status.calendarColor
        : day.isToday
        ? _ReminderTokens.today
        : day.isInSelectedPeriod
        ? _ReminderTokens.successLight
        : Colors.transparent;
    final Color foreground = status != null || day.isToday
        ? Colors.white
        : day.isInVisibleMonth
        ? _ReminderTokens.textStrong
        : _ReminderTokens.textInactive;

    return InkWell(
      borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
      onTap: () => onTap(day.date),
      child: SizedBox(
        height: 24,
        child: Center(
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
            ),
            child: Text(
              '${day.date.day}',
              style: TextStyle(
                color: foreground,
                fontSize: 10,
                fontWeight: status != null || day.isToday
                    ? FontWeight.w900
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderRecord record;
  final double remainingBalanceThisYear;
  final VoidCallback onEditAmount;
  final VoidCallback onDelete;
  final VoidCallback onMarkFinished;

  const _ReminderCard({
    required this.record,
    required this.remainingBalanceThisYear,
    required this.onEditAmount,
    required this.onDelete,
    required this.onMarkFinished,
  });

  @override
  Widget build(BuildContext context) {
    final _ReminderStatus status = _ReminderStatus.fromRecord(record);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 8),
      decoration: BoxDecoration(
        color: _ReminderTokens.surface,
        borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
        border: Border.all(color: status.borderColor),
        boxShadow: _ReminderTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _ReminderDateUtils.fullDate(record.date),
                      style: const TextStyle(
                        color: _ReminderTokens.textStrong,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.payee,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ReminderTokens.textStrong,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 3,
                      children: <Widget>[
                        Text(
                          record.category,
                          style: const TextStyle(
                            color: _ReminderTokens.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          record.reminderCount,
                          style: const TextStyle(
                            color: _ReminderTokens.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    formatMoney(record.amount),
                    style: TextStyle(
                      color: status.amountColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      decoration: status == _ReminderStatus.paid
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _ReminderStatusChip(status: status),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _ReminderIconActionButton(
                        tooltip: 'Completed',
                        icon: Icons.check_circle,
                        iconColor: _ReminderTokens.success,
                        onPressed: onMarkFinished,
                      ),
                      const SizedBox(width: 5),
                      _ReminderIconActionButton(
                        tooltip: 'Edit Amount',
                        icon: Icons.edit_outlined,
                        iconColor: _ReminderTokens.blue,
                        onPressed: onEditAmount,
                      ),
                      const SizedBox(width: 5),
                      _ReminderIconActionButton(
                        tooltip: 'Delete',
                        icon: Icons.delete_outline,
                        iconColor: _ReminderTokens.dangerDark,
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (record.isRecurring) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Remaining balance this year',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ReminderTokens.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatMoney(remainingBalanceThisYear),
                  style: const TextStyle(
                    color: _ReminderTokens.textStrong,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum _ReminderStatus {
  upcoming('Upcoming'),
  overdue('Overdue'),
  paid('Paid');

  final String label;

  const _ReminderStatus(this.label);

  static _ReminderStatus fromRecord(ReminderRecord record) {
    if (record.amount <= 0) return _ReminderStatus.paid;

    final DateTime today = _ReminderDateUtils.dateOnly(AppClock.now);
    final DateTime dueDate = _ReminderDateUtils.dateOnly(record.date);
    return dueDate.isBefore(today)
        ? _ReminderStatus.overdue
        : _ReminderStatus.upcoming;
  }

  Color get calendarColor {
    return switch (this) {
      _ReminderStatus.upcoming => _ReminderTokens.success,
      _ReminderStatus.overdue => _ReminderTokens.danger,
      _ReminderStatus.paid => _ReminderTokens.warning,
    };
  }

  Color get amountColor {
    return switch (this) {
      _ReminderStatus.upcoming => _ReminderTokens.warning,
      _ReminderStatus.overdue => _ReminderTokens.dangerDark,
      _ReminderStatus.paid => _ReminderTokens.textMuted,
    };
  }

  Color get borderColor {
    return switch (this) {
      _ReminderStatus.upcoming => const Color(0xFFF3D889),
      _ReminderStatus.overdue => const Color(0xFFE7A2A2),
      _ReminderStatus.paid => _ReminderTokens.border,
    };
  }

  Color get chipColor {
    return switch (this) {
      _ReminderStatus.upcoming => _ReminderTokens.warning,
      _ReminderStatus.overdue => _ReminderTokens.dangerDark,
      _ReminderStatus.paid => _ReminderTokens.success,
    };
  }
}

class _ReminderStatusChip extends StatelessWidget {
  final _ReminderStatus status;

  const _ReminderStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: status.chipColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          status.label,
          style: TextStyle(
            color: status.chipColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ReminderIconActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _ReminderIconActionButton({
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: IconButton(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: _ReminderTokens.compactActionBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
          ),
        ),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 15, color: iconColor),
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
        color: _ReminderTokens.surface,
        borderRadius: BorderRadius.circular(_ReminderTokens.cardRadius),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.notifications_none,
            color: _ReminderTokens.textInactive,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Tap a date to create a reminder.',
            textAlign: TextAlign.center,
            style: _ReminderTokens.emptyLabel,
          ),
        ],
      ),
    );
  }
}

class _AmountEditDialog extends StatefulWidget {
  final ReminderRecord record;

  const _AmountEditDialog({required this.record});

  @override
  State<_AmountEditDialog> createState() => _AmountEditDialogState();
}

class _AmountEditDialogState extends State<_AmountEditDialog> {
  late final TextEditingController _controller;
  late final FocusNode _amountFocusNode;
  late bool _applyToSeries;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.record.amount.toStringAsFixed(2),
    );
    _amountFocusNode = FocusNode();
    _applyToSeries = widget.record.isRecurring;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(Duration.zero, () {
        if (mounted) _amountFocusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit amount'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _controller,
            focusNode: _amountFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[_moneyInputFormatter],
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: r'$',
            ),
          ),
          if (widget.record.isRecurring) ...<Widget>[
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _applyToSeries,
              onChanged: (bool value) {
                setState(() => _applyToSeries = value);
              },
              title: const Text(
                'Apply to all recurring reminders',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final double amount = parseMoney(_controller.text);
            if (amount <= 0) return;
            Navigator.pop(
              context,
              _AmountEditResult(
                amount: amount,
                applyToSeries: widget.record.isRecurring && _applyToSeries,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _DeleteRecurringReminderDialog extends StatelessWidget {
  const _DeleteRecurringReminderDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete recurring schedule?'),
      content: const Text(
        'This removes future reminders and linked recurring expenses. Completed expense history is kept.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _ReminderTokens.dangerDark,
          ),
          onPressed: () => Navigator.pop(context, ReminderDeleteScope.series),
          child: const Text('Delete schedule'),
        ),
      ],
    );
  }
}

class _DeleteReminderDialog extends StatelessWidget {
  const _DeleteReminderDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete reminder?'),
      content: const Text('This reminder will be permanently deleted.'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _ReminderTokens.dangerDark,
          ),
          onPressed: () => Navigator.pop(context, ReminderDeleteScope.single),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class _CreateReminderList extends StatelessWidget {
  final List<_ReminderFormData> forms;
  final ValueChanged<_ReminderFormData> onPickDate;
  final ValueChanged<_ReminderFormData> onRemove;
  final VoidCallback onAdd;
  final void Function(_ReminderFormData form, String category)
  onCategoryChanged;
  final void Function(_ReminderFormData form, String count)
  onReminderCountChanged;

  const _CreateReminderList({
    required this.forms,
    required this.onPickDate,
    required this.onRemove,
    required this.onAdd,
    required this.onCategoryChanged,
    required this.onReminderCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: _ReminderTokens.createPagePadding,
      itemCount: forms.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == forms.length) {
          return _AddReminderButton(onPressed: onAdd);
        }

        final _ReminderFormData form = forms[index];
        return _ReminderForm(
          form: form,
          canRemove: forms.length > 1,
          onPickDate: () => onPickDate(form),
          onRemove: () => onRemove(form),
          onCategoryChanged: (String category) {
            onCategoryChanged(form, category);
          },
          onReminderCountChanged: (String count) {
            onReminderCountChanged(form, count);
          },
        );
      },
    );
  }
}

class _AddReminderButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddReminderButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.note_add_outlined,
          color: _ReminderTokens.iconBlue,
        ),
        label: const Text(
          'Add more reminder',
          style: _ReminderTokens.addButtonLabel,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
          ),
          side: const BorderSide(color: _ReminderTokens.inputBorder),
        ),
      ),
    );
  }
}

class _ReminderForm extends StatelessWidget {
  final _ReminderFormData form;
  final bool canRemove;
  final VoidCallback onPickDate;
  final VoidCallback onRemove;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onReminderCountChanged;

  const _ReminderForm({
    required this.form,
    required this.canRemove,
    required this.onPickDate,
    required this.onRemove,
    required this.onCategoryChanged,
    required this.onReminderCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: <Widget>[
          if (canRemove)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  color: _ReminderTokens.danger,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _FormFieldShell(
                  label: 'DATE',
                  isRequired: true,
                  child: InkWell(
                    onTap: onPickDate,
                    child: _InputLikeBox(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(_ReminderDateUtils.fullDate(form.date)),
                          ),
                          const Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: _ReminderTokens.iconBlue,
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
                          color: _ReminderTokens.iconBlue,
                        ),
                        items: _categoryItems,
                        onChanged: (String? value) {
                          if (value == null) return;
                          onCategoryChanged(value);
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
            children: <Widget>[
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
                      inputFormatters: <TextInputFormatter>[
                        _moneyInputFormatter,
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
                        items: _reminderCountItems,
                        onChanged: (String? value) {
                          if (value == null) return;
                          onReminderCountChanged(value);
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

  static final List<DropdownMenuItem<String>> _categoryItems = _categories
      .map<DropdownMenuItem<String>>(
        (String category) =>
            DropdownMenuItem<String>(value: category, child: Text(category)),
      )
      .toList(growable: false);

  static final List<DropdownMenuItem<String>> _reminderCountItems =
      _reminderCounts
          .map<DropdownMenuItem<String>>(
            (String count) =>
                DropdownMenuItem<String>(value: count, child: Text(count)),
          )
          .toList(growable: false);
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
      children: <Widget>[
        RichText(
          text: TextSpan(
            style: _ReminderTokens.fieldLabel,
            children: <InlineSpan>[
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: _ReminderTokens.danger),
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
        color: _ReminderTokens.surface,
        borderRadius: BorderRadius.circular(_ReminderTokens.controlRadius),
        boxShadow: _ReminderTokens.inputShadow,
      ),
      child: DefaultTextStyle(style: _ReminderTokens.inputText, child: child),
    );
  }
}
