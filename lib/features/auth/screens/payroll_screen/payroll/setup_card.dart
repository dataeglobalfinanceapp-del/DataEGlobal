part of '../payroll_screen.dart';

class _PayrollSetupCard extends StatelessWidget {
  final PayrollViewState state;

  const _PayrollSetupCard({required this.state});

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
              _PayrollHeaderMetrics(
                balance: state.balance,
                totalPay: state.payPeriodTotalPay,
              ),
              if (payroll.unconfirmedEmployeeCount > 0) ...<Widget>[
                const SizedBox(height: 16),
                const Divider(height: 1, color: _PayrollTokens.divider),
                const SizedBox(height: 16),
                _PayrollConfirmationCaution(
                  unconfirmedCount: payroll.unconfirmedEmployeeCount,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PayrollConfirmationCaution extends StatelessWidget {
  final int unconfirmedCount;

  const _PayrollConfirmationCaution({required this.unconfirmedCount});

  @override
  Widget build(BuildContext context) {
    final String employeeLabel = unconfirmedCount == 1
        ? 'employee still needs'
        : 'employees still need';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _PayrollTokens.warningBackground,
        borderRadius: BorderRadius.circular(_PayrollTokens.controlRadius),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            color: _PayrollTokens.warning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$unconfirmedCount $employeeLabel to confirm payroll.',
              style: _PayrollTokens.cautionText,
            ),
          ),
        ],
      ),
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
