import 'package:flutter/material.dart';

typedef SummaryCardBuilder =
    Widget Function(BuildContext context, SummaryCardMetrics metrics);

typedef SummaryCardHeightBuilder = double Function(SummaryCardMetrics metrics);

class SummaryCardShell extends StatelessWidget {
  final Key? cardKey;
  final SummaryCardBuilder builder;
  final SummaryCardHeightBuilder? heightBuilder;

  const SummaryCardShell({
    super.key,
    this.cardKey,
    required this.builder,
    this.heightBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final mediaSize = MediaQuery.sizeOf(context);
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : mediaSize.width;
          final metrics = SummaryCardMetrics.fromSize(
            width: width,
            height: mediaSize.height,
          );
          final card = Container(
            key: cardKey,
            width: double.infinity,
            padding: EdgeInsets.all(metrics.padding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF064A42), Color(0xFF052D2E)],
              ),
              borderRadius: BorderRadius.circular(metrics.borderRadius),
              border: Border.all(
                color: SummaryCardTokens.goldBorder,
                width: SummaryCardTokens.borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: SummaryCardTokens.shadowColor.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: builder(context, metrics),
          );

          final height = heightBuilder?.call(metrics);
          return height == null ? card : SizedBox(height: height, child: card);
        },
      ),
    );
  }
}

class SummaryCardMetrics {
  final double width;
  final double heightScale;
  final bool isTablet;

  const SummaryCardMetrics._({
    required this.width,
    required this.heightScale,
    required this.isTablet,
  });

  factory SummaryCardMetrics.fromSize({
    required double width,
    required double height,
  }) {
    return SummaryCardMetrics._(
      width: width,
      heightScale: (height / 844).clamp(0.78, 1.15).toDouble(),
      isTablet: width >= 600,
    );
  }

  double get balanceCardHeight {
    final baseHeight = width >= 600
        ? 170.0
        : width >= 380
        ? 145.0
        : 150.0;
    return (baseHeight * heightScale)
        .clamp(isTablet ? 150.0 : 112.0, isTablet ? 190.0 : 160.0)
        .toDouble();
  }

  double get padding => ((isTablet ? 18.0 : 14.0) * heightScale)
      .clamp(isTablet ? 14.0 : 10.0, isTablet ? 20.0 : 14.0)
      .toDouble();

  double get borderRadius => isTablet ? 22 : 18;

  double get primaryLabelFontSize => ((isTablet ? 12.0 : 10.0) * heightScale)
      .clamp(isTablet ? 10.5 : 8.5, isTablet ? 13.0 : 10.0)
      .toDouble();

  double get primaryAmountFontSize => ((isTablet ? 26.0 : 22.0) * heightScale)
      .clamp(isTablet ? 28.0 : 20.0, isTablet ? 38.0 : 28.0)
      .toDouble();

  double get primaryVerticalGap => isTablet ? 6 : 2;

  double get sectionGap => isTablet ? 10 : 6;

  double get columnDividerHeight => ((isTablet ? 44.0 : 30.0) * heightScale)
      .clamp(isTablet ? 36.0 : 22.0, isTablet ? 48.0 : 30.0)
      .toDouble();

  double get tallColumnDividerHeight => ((isTablet ? 78.0 : 74.0) * heightScale)
      .clamp(isTablet ? 68.0 : 58.0, isTablet ? 96.0 : 86.0)
      .toDouble();

  double get columnDividerMargin => ((isTablet ? 14.0 : 10.0) * heightScale)
      .clamp(isTablet ? 10.0 : 7.0, isTablet ? 16.0 : 10.0)
      .toDouble();
}

class SummaryCardSectionDivider extends StatelessWidget {
  const SummaryCardSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: SummaryCardTokens.goldBorder.withValues(alpha: 0.44),
    );
  }
}

class SummaryCardColumnDivider extends StatelessWidget {
  final double height;
  final double horizontalMargin;

  const SummaryCardColumnDivider({
    super.key,
    required this.height,
    required this.horizontalMargin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      color: SummaryCardTokens.goldBorder.withValues(alpha: 0.28),
    );
  }
}

class SummaryCardTokens {
  const SummaryCardTokens._();

  static const Color goldBorder = Color(0xFFBCA052);
  static const Color shadowColor = Color(0xFF052D2E);
  static const Color label = Color(0xFFC6E2CE);
  static const Color secondaryLabel = Color(0xFFE8F4DC);
  static const Color balanceAmount = Color(0xFFFFC84D);
  static const Color dangerAmount = Color(0xFFFF5E63);
  static const Color successAmount = Color(0xFF76C95F);
  static const Color supportingAmount = Color(0xFF93C5FD);
  static const double borderWidth = 1.2;
}
