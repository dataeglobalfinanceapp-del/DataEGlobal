import 'package:flutter/material.dart';

import 'package:savetep/features/auth/models/balance_summary_data.dart';
import 'package:savetep/services/money_formatter.dart';

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
        ? const Color(0xFF76C95F)
        : const Color(0xFFFF5E63);

    return ConstrainedBox(
      constraints: const BoxConstraints(),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final mediaSize = MediaQuery.sizeOf(context);
          final heightScale = (mediaSize.height / 844)
              .clamp(0.78, 1.15)
              .toDouble();
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : mediaSize.width;
          final isTablet = width >= 600;
          final baseHeight = width >= 600
              ? 170.0
              : width >= 380
              ? 145.0
              : 150.0;
          final height = (baseHeight * heightScale)
              .clamp(isTablet ? 150.0 : 112.0, isTablet ? 190.0 : 160.0)
              .toDouble();
          final padding = ((isTablet ? 18.0 : 14.0) * heightScale)
              .clamp(isTablet ? 14.0 : 10.0, isTablet ? 20.0 : 14.0)
              .toDouble();
          final labelFontSize = ((isTablet ? 12.0 : 10.0) * heightScale)
              .clamp(isTablet ? 10.5 : 8.5, isTablet ? 13.0 : 10.0)
              .toDouble();
          final amountFontSize = ((isTablet ? 26.0 : 22.0) * heightScale)
              .clamp(isTablet ? 28.0 : 20.0, isTablet ? 38.0 : 28.0)
              .toDouble();
          final metricDividerHeight = ((isTablet ? 44.0 : 30.0) * heightScale)
              .clamp(isTablet ? 36.0 : 22.0, isTablet ? 48.0 : 30.0)
              .toDouble();
          final metricDividerMargin = ((isTablet ? 14.0 : 10.0) * heightScale)
              .clamp(isTablet ? 10.0 : 7.0, isTablet ? 16.0 : 10.0)
              .toDouble();

          return SizedBox(
            height: height,
            child: Container(
              key: cardKey,
              width: double.infinity,
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF064A42), Color(0xFF052D2E)],
                ),
                borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
                border: Border.all(color: const Color(0xFFBCA052), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF052D2E).withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
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
                            amountColor: const Color(0xFFFFC84D),
                            labelFontSize: labelFontSize,
                            amountFontSize: amountFontSize,
                            verticalGap: isTablet ? 6 : 2,
                          ),
                        ),
                        _SummaryColumnDivider(
                          height: metricDividerHeight,
                          horizontalMargin: metricDividerMargin,
                        ),
                        Expanded(
                          child: _PrimarySummaryMetric(
                            label: _estimatedTaxAtYearEndLabel,
                            value: formatMoney(data.estimatedTaxAtYearEnd),
                            amountColor: const Color(0xFFFF5E63),
                            labelFontSize: labelFontSize,
                            amountFontSize: amountFontSize,
                            verticalGap: isTablet ? 6 : 2,
                            onTap: onEstimatedTaxTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: const Color(0xFFBCA052).withValues(alpha: 0.44),
                  ),
                  SizedBox(height: isTablet ? 10 : 6),
                  Row(
                    children: [
                      Expanded(
                        child: _SecondarySummaryMetric(
                          label: _totalExpenseLabel,
                          amount: data.totalExpense,
                          icon: Icons.south_west_rounded,
                          iconColor: const Color(0xFFFF5E63),
                          amountColor: const Color(0xFFFF5E63),
                          isTablet: isTablet,
                        ),
                      ),
                      _SummaryColumnDivider(
                        height: metricDividerHeight,
                        horizontalMargin: metricDividerMargin,
                      ),
                      Expanded(
                        child: _SecondarySummaryMetric(
                          label: _totalDepositLabel,
                          amount: data.totalDeposit,
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: depositColor,
                          amountColor: depositColor,
                          isTablet: isTablet,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
            color: const Color(0xFFC6E2CE),
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

class _SummaryColumnDivider extends StatelessWidget {
  final double height;
  final double horizontalMargin;

  const _SummaryColumnDivider({
    required this.height,
    required this.horizontalMargin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      color: const Color(0xFFBCA052).withValues(alpha: 0.28),
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
                  color: const Color(0xFFE8F4DC),
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
