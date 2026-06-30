part of '../payroll_screen.dart';

class _PayrollSetupCard extends StatelessWidget {
  final PayrollViewState state;
  final VoidCallback onPickPayDate;
  final VoidCallback onChooseProcessDays;
  final ValueChanged<PayrollSchedule> onScheduleChanged;

  const _PayrollSetupCard({
    required this.state,
    required this.onPickPayDate,
    required this.onChooseProcessDays,
    required this.onScheduleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final PayrollRecord payroll = state.payroll;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool narrow = constraints.maxWidth < 560;

        return Container(
          decoration: _PayrollTokens.panelDecoration,
          padding: EdgeInsets.all(narrow ? 16 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (narrow) ...<Widget>[
                _PayrollHeaderMetrics(
                  balance: state.balance,
                  totalPay: state.payPeriodTotalPay,
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: _PayrollTokens.divider),
                const SizedBox(height: 18),
                _ProcessDateField(
                  processDate: payroll.processDate,
                  onTap: onChooseProcessDays,
                ),
              ] else ...<Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _PayrollHeaderMetrics(
                        balance: state.balance,
                        totalPay: state.payPeriodTotalPay,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 80,
                      color: _PayrollTokens.divider,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _ProcessDateField(
                        processDate: payroll.processDate,
                        onTap: onChooseProcessDays,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              const Divider(height: 1, color: _PayrollTokens.divider),
              const SizedBox(height: 18),
              _ResponsiveFieldPair(
                first: _DateInputTile(
                  label: 'PAY DATE',
                  value: _formatDate(payroll.payDate),
                  onTap: onPickPayDate,
                ),
                second: _ScheduleDropdown(
                  value: payroll.schedule,
                  onChanged: onScheduleChanged,
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: _PayrollTokens.divider),
              const SizedBox(height: 18),
              _ReadOnlyField(
                label: 'PAY PERIOD',
                value:
                    '${_formatDate(payroll.payPeriodStart)} - ${_formatDate(payroll.payPeriodEnd)}',
                trailing: const Icon(
                  Icons.keyboard_arrow_down,
                  color: _PayrollTokens.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: _PayrollTokens.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      payroll.processInstruction,
                      style: _PayrollTokens.helperText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PayrollHeaderMetrics extends StatelessWidget {
  final double balance;
  final double totalPay;

  const _PayrollHeaderMetrics({required this.balance, required this.totalPay});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SummaryMetric(label: 'BALANCE', value: formatMoney(balance)),
              const SizedBox(height: 16),
              _SummaryMetric(label: 'TOTAL PAY', value: formatMoney(totalPay)),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _SummaryMetric(
                label: 'BALANCE',
                value: formatMoney(balance),
              ),
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 76, color: _PayrollTokens.divider),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryMetric(
                label: 'TOTAL PAY',
                value: formatMoney(totalPay),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 16),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: _PayrollTokens.balanceValue),
        ),
      ],
    );
  }
}

class _ProcessDateField extends StatelessWidget {
  final DateTime processDate;
  final VoidCallback onTap;

  const _ProcessDateField({required this.processDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('PROCESS PAYROLL DATE', style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        _TappableField(
          value: _formatDate(processDate),
          icon: Icons.calendar_month_outlined,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _ResponsiveFieldPair extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _ResponsiveFieldPair({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            children: <Widget>[first, const SizedBox(height: 14), second],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: first),
            const SizedBox(width: 14),
            Container(width: 1, height: 70, color: _PayrollTokens.divider),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _DateInputTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateInputTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        _TappableField(
          value: value,
          icon: Icons.calendar_month_outlined,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _ScheduleDropdown extends StatelessWidget {
  final PayrollSchedule value;
  final ValueChanged<PayrollSchedule> onChanged;

  const _ScheduleDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('PAYROLL SCHEDULE', style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        DropdownButtonFormField<PayrollSchedule>(
          initialValue: value,
          icon: const Icon(Icons.keyboard_arrow_down),
          isExpanded: true,
          decoration: _PayrollTokens.inputDecoration,
          items: PayrollSchedule.values
              .map(
                (PayrollSchedule schedule) => DropdownMenuItem<PayrollSchedule>(
                  value: schedule,
                  child: Text(schedule.label),
                ),
              )
              .toList(growable: false),
          onChanged: (PayrollSchedule? schedule) {
            if (schedule == null) return;
            onChanged(schedule);
          },
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _PayrollTokens.fieldLabel),
        const SizedBox(height: 14),
        Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: _PayrollTokens.inputBoxDecoration,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _PayrollTokens.inputText,
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }
}

class _TappableField extends StatelessWidget {
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _TappableField({
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: _PayrollTokens.inputBoxDecoration,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _PayrollTokens.inputText,
                ),
              ),
              Icon(icon, color: _PayrollTokens.textMuted, size: 25),
            ],
          ),
        ),
      ),
    );
  }
}
