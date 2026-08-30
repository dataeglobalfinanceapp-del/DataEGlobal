import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/core/customer_service_contact.dart';
import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/screens/user_settings/user_settings_routes.dart';
import 'package:savetep/providers/business_profile_provider.dart';

import 'controllers/home_screen_controller.dart';
import 'models/home_date_range.dart';
import 'widgets/budget_donut_chart.dart';
import 'widgets/home_account_button.dart';

class _HomeLayoutTokens {
  const _HomeLayoutTokens._();

  static const double appBarHeight = 56;
  static const double headerActionsWidth = 96;
  static const double _referenceContentHeight = 700;

  static _HomeLayoutMetrics fromConstraints(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final mediaSize = MediaQuery.sizeOf(context);
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : mediaSize.width;
    final height = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : mediaSize.height;

    return _HomeLayoutMetrics(width: width, availableHeight: height);
  }
}

class _HomeLayoutMetrics {
  final double width;
  final double availableHeight;

  const _HomeLayoutMetrics({
    required this.width,
    required this.availableHeight,
  });

  double get scaleFactor =>
      (availableHeight / _HomeLayoutTokens._referenceContentHeight)
          .clamp(0.78, 1.15)
          .toDouble();

  bool get isTablet => width >= 600;

  double get maxContentWidth => isTablet ? 760 : double.infinity;

  double get pagePadding {
    if (width >= 600) return 24;
    if (width >= 380) return 8;
    return 8;
  }

  double get contentWidth {
    final paddedWidth = math.max(0.0, width - (pagePadding * 2));
    return maxContentWidth.isFinite
        ? math.min(paddedWidth, maxContentWidth)
        : paddedWidth;
  }

  double get topPadding =>
      _scaled(isTablet ? 12 : 8, min: isTablet ? 8 : 5, max: 14);

  double get bottomPadding =>
      _scaled(isTablet ? 12 : 6, min: isTablet ? 8 : 4, max: 16);

  double get datePickerHeight =>
      _scaled(isTablet ? 46 : 38, min: isTablet ? 40 : 30, max: 50);

  double get tabHeight =>
      _scaled(isTablet ? 40 : 34, min: isTablet ? 34 : 27, max: 44);

  double get tabGap =>
      _scaled(isTablet ? 12 : 8, min: isTablet ? 8 : 4, max: 14);

  double get sectionGap =>
      _scaled(isTablet ? 18 : 10, min: isTablet ? 14 : 6, max: 20);

  double get compactSectionGap =>
      _scaled(isTablet ? 12 : 8, min: isTablet ? 8 : 4, max: 14);

  int get actionCrossAxisCount {
    if (width >= 900) return 6;
    if (width >= 600) return 5;
    if (width >= 380) return 4;
    return 3;
  }

  double get actionGridSpacing =>
      _scaled(isTablet ? 14 : 8, min: isTablet ? 10 : 5, max: 16);

  double budgetSectionHeight(int itemCount) {
    final fixedWithoutBudget = _fixedHeightWithoutBudgetAndGrid;
    final budgetRoomAfterGrid =
        availableHeight - fixedWithoutBudget - _minimumGridHeight(itemCount);

    return math
        .min(
          _preferredBudgetSectionHeight,
          math.max(_minimumBudgetSectionHeight, budgetRoomAfterGrid),
        )
        .toDouble();
  }

  double contentHeight(int itemCount) {
    final fixedHeight = _fixedHeightWithoutGrid(itemCount);
    final minimumHeight = fixedHeight + _minimumGridHeight(itemCount);
    final preferredHeight = fixedHeight + _preferredGridHeight(itemCount);

    if (isTablet) {
      return math.max(
        minimumHeight,
        math.min(availableHeight, preferredHeight),
      );
    }

    return math.max(availableHeight, minimumHeight);
  }

  double actionGridHeight(int itemCount) {
    return math.max(
      _minimumGridHeight(itemCount),
      contentHeight(itemCount) - _fixedHeightWithoutGrid(itemCount),
    );
  }

  double actionGridAspectRatio(int itemCount) {
    final columns = actionCrossAxisCount;
    final rows = _actionRowCount(itemCount);
    final tileWidth =
        (contentWidth - (actionGridSpacing * (columns - 1))) / columns;
    final gridHeight = actionGridHeight(itemCount);
    final tileHeight = (gridHeight - (actionGridSpacing * (rows - 1))) / rows;

    return tileWidth / math.max(tileHeight, 1);
  }

  double actionTileHeight(int itemCount) {
    final rows = _actionRowCount(itemCount);
    return (actionGridHeight(itemCount) - (actionGridSpacing * (rows - 1))) /
        rows;
  }

  double actionTileHorizontalPadding(int itemCount) {
    final tileHeight = actionTileHeight(itemCount);
    return (tileHeight * 0.12)
        .clamp(isTablet ? 8.0 : 4.0, isTablet ? 14.0 : 8.0)
        .toDouble();
  }

  double actionTileVerticalPadding(int itemCount) {
    final tileHeight = actionTileHeight(itemCount);
    return (tileHeight * 0.1)
        .clamp(isTablet ? 8.0 : 3.0, isTablet ? 14.0 : 10.0)
        .toDouble();
  }

  double actionIconSize(int itemCount) {
    final tileHeight = actionTileHeight(itemCount);
    return (tileHeight * 0.34)
        .clamp(isTablet ? 24.0 : 16.0, isTablet ? 30.0 : 26.0)
        .toDouble();
  }

  double actionFontSize(int itemCount) {
    final tileHeight = actionTileHeight(itemCount);
    return (tileHeight * 0.18)
        .clamp(isTablet ? 11.0 : 8.5, isTablet ? 13.0 : 12.0)
        .toDouble();
  }

  double actionLabelGap(int itemCount) {
    final tileHeight = actionTileHeight(itemCount);
    return (tileHeight * 0.08)
        .clamp(isTablet ? 8.0 : 3.0, isTablet ? 12.0 : 8.0)
        .toDouble();
  }

  double actionTileRadius(int itemCount) {
    final tileHeight = actionTileHeight(itemCount);
    return (tileHeight * 0.18)
        .clamp(isTablet ? 14.0 : 10.0, isTablet ? 20.0 : 16.0)
        .toDouble();
  }

  int _actionRowCount(int itemCount) {
    return math.max(1, (itemCount / actionCrossAxisCount).ceil());
  }

  double get _fixedHeightWithoutBudgetAndGrid {
    return topPadding +
        datePickerHeight +
        compactSectionGap +
        tabHeight +
        sectionGap +
        sectionGap +
        bottomPadding;
  }

  double _fixedHeightWithoutGrid(int itemCount) {
    return _fixedHeightWithoutBudgetAndGrid + budgetSectionHeight(itemCount);
  }

  double _minimumGridHeight(int itemCount) {
    final rows = _actionRowCount(itemCount);
    return (_minimumTileHeight * rows) + (actionGridSpacing * (rows - 1));
  }

  double _preferredGridHeight(int itemCount) {
    final rows = _actionRowCount(itemCount);
    return (_preferredTileHeight * rows) + (actionGridSpacing * (rows - 1));
  }

  double get _preferredBudgetSectionHeight => _scaled(
    isTablet ? 600 : 455,
    min: isTablet ? 500 : 405,
    max: isTablet ? 660 : 470,
  );

  double get _minimumBudgetSectionHeight => _scaled(
    isTablet ? 560 : 405,
    min: isTablet ? 460 : 370,
    max: isTablet ? 620 : 440,
  );

  double get _minimumTileHeight =>
      _scaled(isTablet ? 86 : 52, min: isTablet ? 78 : 42, max: 100);

  double get _preferredTileHeight =>
      _scaled(isTablet ? 104 : 80, min: isTablet ? 92 : 58, max: 122);

  double _scaled(double value, {required double min, required double max}) {
    return (value * scaleFactor).clamp(min, max).toDouble();
  }
}

class _HomeFeatureAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final Color textColor;
  final String? routeName;

  const _HomeFeatureAction({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColor = const Color(0xFF1E40AF),
    this.textColor = Colors.black87,
    this.routeName,
  });
}

const List<_HomeFeatureAction> _homeFeatureActions = <_HomeFeatureAction>[
  _HomeFeatureAction(
    icon: Icons.account_balance_wallet_outlined,
    label: 'Deposit',
    color: Color(0xFFDFF7EA),
    iconColor: Color(0xFF0F766E),
    textColor: Color(0xFF064E3B),
    routeName: '/scan-deposit',
  ),
  _HomeFeatureAction(
    icon: Icons.receipt_long_outlined,
    label: 'Expense',
    color: Color(0xFFFFE8D6),
    iconColor: Color(0xFFB45309),
    textColor: Color(0xFF7C2D12),
    routeName: '/scan-expense',
  ),
  _HomeFeatureAction(
    icon: Icons.receipt,
    label: 'Transactions',
    color: Color(0xFFE0F2FE),
    routeName: '/transactions',
  ),
  _HomeFeatureAction(
    icon: Icons.account_balance_wallet_outlined,
    label: 'Savings',
    color: Color.fromARGB(255, 255, 199, 161),
    iconColor: Color(0xFF166534),
    textColor: Color.fromARGB(255, 12, 99, 4),
    routeName: '/saving',
  ),
  _HomeFeatureAction(
    icon: Icons.flag,
    label: 'Profit &\nLoss',
    color: Color(0xFFE0F2FE),
    routeName: '/profit-loss',
  ),
  _HomeFeatureAction(
    icon: Icons.credit_card,
    label: 'Liabilities',
    color: Color(0xFFFED7AA),
    routeName: '/liabilities',
  ),
  _HomeFeatureAction(
    icon: Icons.people,
    label: 'Payroll',
    color: Color(0xFFFECDD3),
    routeName: '/payroll',
  ),
  _HomeFeatureAction(
    icon: Icons.trending_up,
    label: 'Investments',
    color: Color(0xFFFCE7F3),
  ),
  _HomeFeatureAction(
    icon: Icons.campaign,
    label: 'Marketing',
    color: Color(0xFFE9D5FF),
  ),
  _HomeFeatureAction(
    icon: Icons.notifications,
    label: 'Reminder',
    color: Color(0xFFFCE7F3),
    routeName: '/reminders',
  ),
  _HomeFeatureAction(
    icon: Icons.flag_outlined,
    label: 'Goal',
    color: Color(0xFFFFF7ED),
    iconColor: Color(0xFFC2410C),
    textColor: Color(0xFF7C2D12),
  ),
  _HomeFeatureAction(
    icon: Icons.shopping_bag_outlined,
    label: 'Shopping',
    color: Color(0xFFFFF1F2),
    iconColor: Color(0xFFBE123C),
    textColor: Color(0xFF881337),
  ),
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final HomeScreenController _screenController;

  @override
  void initState() {
    super.initState();
    _screenController = HomeScreenController()
      ..addListener(_onStateChanged)
      ..start();
  }

  @override
  void dispose() {
    _screenController
      ..removeListener(_onStateChanged)
      ..dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openAndRefresh(String routeName) async {
    await Navigator.pushNamed(context, routeName);
    if (!mounted) return;
    await _screenController.loadBudgetData();
  }

  Future<void> _showCustomerService() async {
    final shouldCall = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer Service'),
        content: const Text(CustomerServiceContact.displayPhone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Call'),
          ),
        ],
      ),
    );
    if (shouldCall != true || !mounted) return;

    final opened = await _screenController.callCustomerService();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(businessProfileProvider);
    final displayName = profile.when(
      data: (profile) => profile.displayName,
      loading: () => BusinessProfile.fallbackDisplayName,
      error: (_, _) => BusinessProfile.fallbackDisplayName,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5ED),
      appBar: AppBar(
        toolbarHeight: _HomeLayoutTokens.appBarHeight,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leadingWidth: _HomeLayoutTokens.headerActionsWidth,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: _HomeLayoutTokens.appBarHeight,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/save_tep_logo.png',
                key: const ValueKey('home.appLogo'),
                fit: BoxFit.contain,
                semanticLabel: 'SaveTep logo',
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          displayName,
          key: const ValueKey('home.businessDisplayName'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            key: const ValueKey('home.customerServiceButton'),
            tooltip: 'Customer Service',
            onPressed: _showCustomerService,
            icon: const Icon(Icons.support_agent_outlined),
          ),
          HomeAccountButton(
            size: 36,
            onPressed: () =>
                Navigator.pushNamed(context, UserSettingsRoutes.settings),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final metrics = _HomeLayoutTokens.fromConstraints(
            context,
            constraints,
          );
          final featureCount = _homeFeatureActions.length;
          final featureCards = _buildFeatureCards(metrics, featureCount);

          return RefreshIndicator(
            onRefresh: _screenController.loadBudgetData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: metrics.pagePadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: metrics.availableHeight,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: metrics.contentWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: metrics.topPadding),
                          _buildDateRangePill(metrics),
                          SizedBox(height: metrics.compactSectionGap),
                          _HomeDateRangeSelector(
                            metrics: metrics,
                            selectedPeriod: _screenController.selectedPeriod,
                            selectedMonth: _screenController.selectedMonth,
                            selectedQuarter: _screenController.selectedQuarter,
                            availableMonths: _screenController.availableMonths,
                            availableQuarters:
                                _screenController.availableQuarters,
                            onPeriodSelected: _screenController.selectPeriod,
                            onMonthSelected: _screenController.selectMonth,
                            onQuarterSelected: _screenController.selectQuarter,
                          ),
                          SizedBox(height: metrics.sectionGap),
                          _buildBudgetSection(metrics, featureCount),
                          SizedBox(height: metrics.sectionGap),
                          SizedBox(
                            height: metrics.actionGridHeight(featureCount),
                            child: GridView(
                              padding: EdgeInsets.zero,
                              primary: false,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        metrics.actionCrossAxisCount,
                                    crossAxisSpacing: metrics.actionGridSpacing,
                                    mainAxisSpacing: metrics.actionGridSpacing,
                                    childAspectRatio: metrics
                                        .actionGridAspectRatio(featureCount),
                                  ),
                              children: featureCards,
                            ),
                          ),
                          SizedBox(height: metrics.bottomPadding),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFeatureCards(
    _HomeLayoutMetrics metrics,
    int featureCount,
  ) {
    return <Widget>[
      for (final action in _homeFeatureActions)
        _buildFeatureCard(
          metrics: metrics,
          featureCount: featureCount,
          icon: action.icon,
          label: action.label,
          color: action.color,
          iconColor: action.iconColor,
          textColor: action.textColor,
          onTap: action.routeName == null
              ? null
              : () => _openAndRefresh(action.routeName!),
        ),
    ];
  }

  Widget _buildBudgetSection(_HomeLayoutMetrics metrics, int featureCount) {
    final sectionHeight = metrics.budgetSectionHeight(featureCount);
    if (_screenController.isLoadingBudget) {
      final indicatorSize = (sectionHeight * 0.28).clamp(42.0, 72.0).toDouble();
      return SizedBox(
        width: double.infinity,
        height: sectionHeight,
        child: Center(
          child: SizedBox.square(
            dimension: indicatorSize,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: sectionHeight),
      child: SizedBox(
        width: metrics.contentWidth,
        child: BudgetDonutChart(
          homeData: _screenController.budgetData,
          periodKey: _screenController.selectedPeriod.label,
        ),
      ),
    );
  }

  Widget _buildDateRangePill(_HomeLayoutMetrics metrics) {
    final periodLabel = _screenController.dateRangeLabel;

    final bool isTablet = metrics.isTablet;
    final scale = metrics.scaleFactor;
    final horizontalPadding = ((isTablet ? 18 : 14) * scale)
        .clamp(isTablet ? 16.0 : 10.0, isTablet ? 22.0 : 16.0)
        .toDouble();
    final iconSize = ((isTablet ? 20 : 18) * scale)
        .clamp(isTablet ? 18.0 : 15.0, isTablet ? 22.0 : 19.0)
        .toDouble();
    final iconGap = ((isTablet ? 12 : 10) * scale)
        .clamp(isTablet ? 10.0 : 7.0, isTablet ? 14.0 : 11.0)
        .toDouble();
    final fontSize = ((isTablet ? 15 : 13) * scale)
        .clamp(isTablet ? 13.0 : 11.0, isTablet ? 16.0 : 13.0)
        .toDouble();
    final radius = ((isTablet ? 12 : 8) * scale)
        .clamp(isTablet ? 10.0 : 7.0, isTablet ? 14.0 : 10.0)
        .toDouble();

    return Container(
      key: const ValueKey('home.dateRangeCard'),
      width: double.infinity,
      height: metrics.datePickerHeight,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFD7DEC9)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: iconSize,
            color: const Color(0xFF0E5E54),
          ),
          SizedBox(width: iconGap),
          Expanded(
            child: Text(
              periodLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF173E37),
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required _HomeLayoutMetrics metrics,
    required int featureCount,
    required IconData icon,
    required String label,
    required Color color,
    Color iconColor = const Color(0xFF1E40AF),
    Color textColor = Colors.black87,
    String? metricValue,
    String? metricLabel,
    VoidCallback? onTap,
  }) {
    final hasMetric = metricValue != null && metricValue.trim().isNotEmpty;
    final iconSize = hasMetric
        ? metrics.actionIconSize(featureCount) * 0.9
        : metrics.actionIconSize(featureCount);
    final labelFontSize = metrics.actionFontSize(featureCount);
    final metricFontSize = (labelFontSize * 1.18).clamp(10.0, 14.0).toDouble();
    final metricLabelFontSize = (labelFontSize * 0.86)
        .clamp(8.0, 10.0)
        .toDouble();
    final card = Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.actionTileHorizontalPadding(featureCount),
        vertical: metrics.actionTileVerticalPadding(featureCount),
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          metrics.actionTileRadius(featureCount),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: iconColor),
          SizedBox(height: metrics.actionLabelGap(featureCount)),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight: FontWeight.w700,
                height: 1.05,
                color: textColor,
              ),
            ),
          ),
          if (hasMetric) ...[
            SizedBox(height: metrics.actionLabelGap(featureCount) * 0.6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                metricValue,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: metricFontSize,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
            if (metricLabel != null && metricLabel.trim().isNotEmpty) ...[
              SizedBox(height: metrics.actionLabelGap(featureCount) * 0.25),
              Text(
                metricLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: metricLabelFontSize,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.68),
                ),
              ),
            ],
          ],
        ],
      ),
    );

    if (onTap == null) return card;

    return GestureDetector(onTap: onTap, child: card);
  }
}

class _HomeDateRangeSelector extends StatelessWidget {
  final _HomeLayoutMetrics metrics;
  final HomePeriodType selectedPeriod;
  final int selectedMonth;
  final int selectedQuarter;
  final List<HomeMonthOption> availableMonths;
  final List<HomeQuarterOption> availableQuarters;
  final ValueChanged<HomePeriodType> onPeriodSelected;
  final ValueChanged<int> onMonthSelected;
  final ValueChanged<int> onQuarterSelected;

  const _HomeDateRangeSelector({
    required this.metrics,
    required this.selectedPeriod,
    required this.selectedMonth,
    required this.selectedQuarter,
    required this.availableMonths,
    required this.availableQuarters,
    required this.onPeriodSelected,
    required this.onMonthSelected,
    required this.onQuarterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<HomePeriodType> periods = HomePeriodType.values;
    return Row(
      children: <Widget>[
        for (int index = 0; index < periods.length; index += 1) ...<Widget>[
          Expanded(child: _buildPeriodSegment(periods[index])),
          if (index < periods.length - 1) SizedBox(width: metrics.tabGap),
        ],
      ],
    );
  }

  Widget _buildPeriodSegment(HomePeriodType period) {
    return switch (period) {
      HomePeriodType.month => _PeriodMenuAnchor<HomeMonthOption>(
        period: period,
        options: availableMonths,
        optionLabel: (HomeMonthOption option) => option.label,
        isOptionSelected: (HomeMonthOption option) =>
            option.month == selectedMonth,
        onOptionSelected: (HomeMonthOption option) =>
            onMonthSelected(option.month),
        onPeriodSelected: onPeriodSelected,
        buttonBuilder: (VoidCallback onPressed) {
          return _HomePeriodButton(
            label: period.label,
            detail: selectedPeriod == period ? monthNames[selectedMonth] : null,
            isSelected: selectedPeriod == period,
            metrics: metrics,
            onPressed: onPressed,
          );
        },
      ),
      HomePeriodType.quarter => _PeriodMenuAnchor<HomeQuarterOption>(
        period: period,
        options: availableQuarters,
        optionLabel: (HomeQuarterOption option) => option.label,
        isOptionSelected: (HomeQuarterOption option) =>
            option.quarter == selectedQuarter,
        onOptionSelected: (HomeQuarterOption option) =>
            onQuarterSelected(option.quarter),
        onPeriodSelected: onPeriodSelected,
        buttonBuilder: (VoidCallback onPressed) {
          return _HomePeriodButton(
            label: period.label,
            detail: selectedPeriod == period ? 'Q$selectedQuarter' : null,
            isSelected: selectedPeriod == period,
            metrics: metrics,
            onPressed: onPressed,
          );
        },
      ),
      _ => _HomePeriodButton(
        label: period.label,
        isSelected: selectedPeriod == period,
        metrics: metrics,
        onPressed: () => onPeriodSelected(period),
      ),
    };
  }
}

class _PeriodMenuAnchor<T> extends StatelessWidget {
  final HomePeriodType period;
  final List<T> options;
  final String Function(T option) optionLabel;
  final bool Function(T option) isOptionSelected;
  final ValueChanged<T> onOptionSelected;
  final ValueChanged<HomePeriodType> onPeriodSelected;
  final Widget Function(VoidCallback onPressed) buttonBuilder;

  const _PeriodMenuAnchor({
    required this.period,
    required this.options,
    required this.optionLabel,
    required this.isOptionSelected,
    required this.onOptionSelected,
    required this.onPeriodSelected,
    required this.buttonBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: options
          .map<Widget>(
            (T option) => MenuItemButton(
              leadingIcon: isOptionSelected(option)
                  ? const Icon(Icons.check, size: 18)
                  : const SizedBox(width: 18),
              onPressed: () => onOptionSelected(option),
              child: Text(optionLabel(option)),
            ),
          )
          .toList(growable: false),
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            return buttonBuilder(() {
              onPeriodSelected(period);
              controller.isOpen ? controller.close() : controller.open();
            });
          },
    );
  }
}

class _HomePeriodButton extends StatelessWidget {
  final String label;
  final String? detail;
  final bool isSelected;
  final _HomeLayoutMetrics metrics;
  final VoidCallback? onPressed;

  const _HomePeriodButton({
    required this.label,
    this.detail,
    required this.isSelected,
    required this.metrics,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTablet = metrics.isTablet;
    final scale = metrics.scaleFactor;
    final radius = ((isTablet ? 12 : 9) * scale)
        .clamp(isTablet ? 10.0 : 7.0, isTablet ? 14.0 : 10.0)
        .toDouble();
    final fontSize = ((isTablet ? 14 : 13) * scale)
        .clamp(isTablet ? 12.0 : 10.5, isTablet ? 15.0 : 13.0)
        .toDouble();
    final detailFontSize = (fontSize * 0.78).clamp(9.0, 11.0).toDouble();

    return SizedBox(
      height: metrics.tabHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF075E54) : Colors.white,
          foregroundColor: isSelected ? Colors.white : const Color(0xFF173E37),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: isSelected
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFD7DEC9), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _PeriodButtonLabel(
            label: label,
            detail: detail,
            fontSize: fontSize,
            detailFontSize: detailFontSize,
          ),
        ),
      ),
    );
  }
}

class _PeriodButtonLabel extends StatelessWidget {
  final String label;
  final String? detail;
  final double fontSize;
  final double detailFontSize;

  const _PeriodButtonLabel({
    required this.label,
    required this.detail,
    required this.fontSize,
    required this.detailFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final String? selectedDetail = detail;
    if (selectedDetail == null || selectedDetail.trim().isEmpty) {
      return Text(
        label,
        maxLines: 1,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          selectedDetail,
          maxLines: 1,
          style: TextStyle(
            fontSize: detailFontSize,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );
  }
}
