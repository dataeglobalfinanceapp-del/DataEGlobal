import 'package:flutter/material.dart';

import 'package:savetep/features/auth/models/balance_summary_data.dart';
import 'package:savetep/services/money_formatter.dart';
import 'summary_card_shell.dart';

const String _totalBalanceLabel = 'TOTAL BALANCE';
const String _estimatedTaxAtYearEndLabel = 'ESTIMATED TAX AT YEAR END';
const String _totalExpenseLabel = 'TOTAL EXPENSE';
const String _totalDepositLabel = 'TOTAL DEPOSIT';

class BalanceSummaryCard extends StatelessWidget {
  final BalanceSummaryData data;
  final Key? cardKey;
  final VoidCallback? onEstimatedTaxTap;

  const BalanceSummaryCard({
    super.key,
    required this.data,
    this.cardKey,
    this.onEstimatedTaxTap,
  });

  @override
  Widget build(BuildContext context) {
    final depositColor = data.totalDeposit >= 0
        ? SummaryCardTokens.successAmount
        : SummaryCardTokens.dangerAmount;

    return SummaryCardShell(
      cardKey: cardKey,
      heightBuilder: (metrics) => metrics.balanceCardHeight,
      builder: (BuildContext context, SummaryCardMetrics metrics) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _PrimarySummaryMetric(
                      label: _totalBalanceLabel,
                      value: formatMoney(data.totalBalance),
                      amountColor: SummaryCardTokens.balanceAmount,
                      labelFontSize: metrics.primaryLabelFontSize,
                      amountFontSize: metrics.primaryAmountFontSize,
                      verticalGap: metrics.primaryVerticalGap,
                    ),
                  ),
                  SummaryCardColumnDivider(
                    height: metrics.columnDividerHeight,
                    horizontalMargin: metrics.columnDividerMargin,
                  ),
                  Expanded(
                    child: _PrimarySummaryMetric(
                      label: _estimatedTaxAtYearEndLabel,
                      value: formatMoney(data.estimatedTaxAtYearEnd),
                      amountColor: SummaryCardTokens.dangerAmount,
                      labelFontSize: metrics.primaryLabelFontSize,
                      amountFontSize: metrics.primaryAmountFontSize,
                      verticalGap: metrics.primaryVerticalGap,
                      onTap: onEstimatedTaxTap,
                    ),
                  ),
                ],
              ),
            ),
            const SummaryCardSectionDivider(),
            SizedBox(height: metrics.sectionGap),
            Row(
              children: [
                Expanded(
                  child: _SecondarySummaryMetric(
                    label: _totalExpenseLabel,
                    amount: data.totalExpense,
                    icon: Icons.south_west_rounded,
                    iconColor: SummaryCardTokens.dangerAmount,
                    amountColor: SummaryCardTokens.dangerAmount,
                    isTablet: metrics.isTablet,
                  ),
                ),
                SummaryCardColumnDivider(
                  height: metrics.columnDividerHeight,
                  horizontalMargin: metrics.columnDividerMargin,
                ),
                Expanded(
                  child: _SecondarySummaryMetric(
                    label: _totalDepositLabel,
                    amount: data.totalDeposit,
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: depositColor,
                    amountColor: depositColor,
                    isTablet: metrics.isTablet,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PrimarySummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color amountColor;
  final double labelFontSize;
  final double amountFontSize;
  final double verticalGap;
  final VoidCallback? onTap;

  const _PrimarySummaryMetric({
    required this.label,
    required this.value,
    required this.amountColor,
    required this.labelFontSize,
    required this.amountFontSize,
    required this.verticalGap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: SummaryCardTokens.label,
            fontSize: labelFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: verticalGap),
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  color: amountColor,
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return content;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _SecondarySummaryMetric extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color amountColor;
  final bool isTablet;

  const _SecondarySummaryMetric({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.amountColor,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final heightScale = (MediaQuery.sizeOf(context).height / 844)
        .clamp(0.78, 1.15)
        .toDouble();
    final iconDimension = ((isTablet ? 38.0 : 26.0) * heightScale)
        .clamp(isTablet ? 32.0 : 21.0, isTablet ? 42.0 : 28.0)
        .toDouble();
    final iconSize = ((isTablet ? 20.0 : 15.0) * heightScale)
        .clamp(isTablet ? 17.0 : 12.0, isTablet ? 22.0 : 16.0)
        .toDouble();
    final gap = ((isTablet ? 10.0 : 6.0) * heightScale)
        .clamp(isTablet ? 8.0 : 4.0, isTablet ? 12.0 : 7.0)
        .toDouble();
    final labelFontSize = ((isTablet ? 11.0 : 9.0) * heightScale)
        .clamp(isTablet ? 9.5 : 7.8, isTablet ? 12.0 : 9.2)
        .toDouble();
    final amountFontSize = ((isTablet ? 18.0 : 14.5) * heightScale)
        .clamp(isTablet ? 15.0 : 12.0, isTablet ? 20.0 : 15.0)
        .toDouble();

    return Row(
      children: [
        Container(
          width: iconDimension,
          height: iconDimension,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 1.2),
            color: iconColor.withValues(alpha: 0.08),
          ),
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SummaryCardTokens.secondaryLabel,
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatMoney(amount),
                  maxLines: 1,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: amountFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
