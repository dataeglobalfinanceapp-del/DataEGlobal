import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:savetep/features/auth/models/budget_data.dart';
import 'package:savetep/features/auth/screens/user_setting/user_settings_routes.dart';
import 'package:savetep/features/auth/screens/user_setting/widgets/user_logo_menu_button.dart';
import 'package:savetep/features/auth/services/auth_service.dart';
import 'package:savetep/services/app_clock.dart';
import 'package:savetep/services/liability_service.dart';
import 'package:savetep/theme/dark_contrast.dart';

import 'budget_donut_chart.dart';

class _HomeLayoutTokens {
  const _HomeLayoutTokens._();

  static const double appBarHeight = 56;
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
    routeName: '/tax',
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
];

enum _HomePeriodType {
  day('Day'),
  week('Week'),
  month('Month'),
  quarter('3 Months');

  const _HomePeriodType(this.label);

  final String label;
}

class _HomeDateRange {
  final DateTime start;
  final DateTime end;

  const _HomeDateRange({required this.start, required this.end});
}

class _MonthOption {
  final int month;
  final String label;

  const _MonthOption({required this.month, required this.label});
}

class _QuarterOption {
  final int quarter;
  final String label;

  const _QuarterOption({required this.quarter, required this.label});
}

class _HomeDateRangeService {
  const _HomeDateRangeService._();

  static const int firstMonth = 1;
  static const int monthsInQuarter = 3;
  static const int weekLookbackDays = 6;

  static _HomeDateRange rangeFor({
    required _HomePeriodType period,
    required int selectedMonth,
    required int selectedQuarter,
    required DateTime today,
  }) {
    final DateTime currentDay = dateOnly(today);

    return switch (period) {
      _HomePeriodType.day => _HomeDateRange(start: currentDay, end: currentDay),
      _HomePeriodType.week => _HomeDateRange(
        start: currentDay.subtract(const Duration(days: weekLookbackDays)),
        end: currentDay,
      ),
      _HomePeriodType.month => _monthRange(
        month: clampMonth(selectedMonth, currentDay),
        today: currentDay,
      ),
      _HomePeriodType.quarter => _quarterRange(
        quarter: clampQuarter(selectedQuarter, currentDay),
        today: currentDay,
      ),
    };
  }

  static List<_MonthOption> availableMonthOptions(DateTime today) {
    final DateTime currentDay = dateOnly(today);
    return List<_MonthOption>.generate(currentDay.month, (int index) {
      final int month = index + 1;
      return _MonthOption(month: month, label: _monthNames[month]);
    }, growable: false);
  }

  static List<_QuarterOption> availableQuarterOptions(DateTime today) {
    final int current = currentQuarter(today);
    return List<_QuarterOption>.generate(current, (int index) {
      final int quarter = index + 1;
      return _QuarterOption(quarter: quarter, label: 'Q$quarter');
    }, growable: false);
  }

  static int currentQuarter(DateTime date) {
    return ((dateOnly(date).month - 1) ~/ monthsInQuarter) + 1;
  }

  static int clampMonth(int month, DateTime today) {
    return month.clamp(firstMonth, dateOnly(today).month).toInt();
  }

  static int clampQuarter(int quarter, DateTime today) {
    return quarter.clamp(1, currentQuarter(today)).toInt();
  }

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static _HomeDateRange _monthRange({
    required int month,
    required DateTime today,
  }) {
    final DateTime start = DateTime(today.year, month);
    final bool isCurrentMonth = month == today.month;
    return _HomeDateRange(
      start: start,
      end: isCurrentMonth ? today : DateTime(today.year, month + 1, 0),
    );
  }

  static _HomeDateRange _quarterRange({
    required int quarter,
    required DateTime today,
  }) {
    final int startMonth = ((quarter - 1) * monthsInQuarter) + firstMonth;
    final int endMonth = startMonth + monthsInQuarter - 1;
    final DateTime start = DateTime(today.year, startMonth);
    final bool isCurrentQuarter = quarter == currentQuarter(today);
    return _HomeDateRange(
      start: start,
      end: isCurrentQuarter ? today : DateTime(today.year, endMonth + 1, 0),
    );
  }
}

const List<String> _monthNames = <String>[
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _HomePeriodType _selectedPeriod = _HomePeriodType.week;
  late int _selectedMonth;
  late int _selectedQuarter;
  late DateTime _startDate;
  late DateTime _endDate;
  BudgetData _budgetData = const BudgetData();
  bool _isLoadingBudget = true;
  int _budgetLoadSerial = 0;

  @override
  void initState() {
    super.initState();
    final DateTime today = AppClock.now;
    _selectedMonth = today.month;
    _selectedQuarter = _HomeDateRangeService.currentQuarter(today);
    LiabilityService.dataVersion.addListener(_handleBudgetDataChanged);
    _updateDateRange();
    unawaited(_loadBudgetData());
  }

  @override
  void dispose() {
    LiabilityService.dataVersion.removeListener(_handleBudgetDataChanged);
    super.dispose();
  }

  void _handleBudgetDataChanged() {
    if (!mounted) return;
    unawaited(_loadBudgetData());
  }

  void _updateDateRange() {
    final DateTime today = AppClock.now;
    _selectedMonth = _HomeDateRangeService.clampMonth(_selectedMonth, today);
    _selectedQuarter = _HomeDateRangeService.clampQuarter(
      _selectedQuarter,
      today,
    );

    final _HomeDateRange range = _HomeDateRangeService.rangeFor(
      period: _selectedPeriod,
      selectedMonth: _selectedMonth,
      selectedQuarter: _selectedQuarter,
      today: today,
    );
    _startDate = range.start;
    _endDate = range.end;
  }

  Future<void> _loadBudgetData() async {
    final loadSerial = ++_budgetLoadSerial;
    setState(() {
      _updateDateRange();
      _isLoadingBudget = true;
    });

    final startDate = _startDate;
    final endDate = _endDate;
    final data = await LiabilityService.loadBudgetData(
      startDate: startDate,
      endDate: endDate,
      period: '${_formatDate(startDate)} - ${_formatDate(endDate)}',
    );

    if (!mounted || loadSerial != _budgetLoadSerial) return;
    setState(() {
      _budgetData = data;
      _isLoadingBudget = false;
    });
  }

  Future<void> _openAndRefresh(String routeName) async {
    await Navigator.pushNamed(context, routeName);
    if (!mounted) return;
    await _loadBudgetData();
  }

  void _selectPeriod(_HomePeriodType period) {
    if (_selectedPeriod == period) return;

    setState(() {
      _selectedPeriod = period;
      _updateDateRange();
    });
    unawaited(_loadBudgetData());
  }

  void _selectMonth(int month) {
    final int availableMonth = _HomeDateRangeService.clampMonth(
      month,
      AppClock.now,
    );
    if (_selectedPeriod == _HomePeriodType.month &&
        _selectedMonth == availableMonth) {
      return;
    }

    setState(() {
      _selectedPeriod = _HomePeriodType.month;
      _selectedMonth = availableMonth;
      _updateDateRange();
    });
    unawaited(_loadBudgetData());
  }

  void _selectQuarter(int quarter) {
    final int availableQuarter = _HomeDateRangeService.clampQuarter(
      quarter,
      AppClock.now,
    );
    if (_selectedPeriod == _HomePeriodType.quarter &&
        _selectedQuarter == availableQuarter) {
      return;
    }

    setState(() {
      _selectedPeriod = _HomePeriodType.quarter;
      _selectedQuarter = availableQuarter;
      _updateDateRange();
    });
    unawaited(_loadBudgetData());
  }

  @override
  Widget build(BuildContext context) {
    final darkContrast = DarkContrastScope.of(context);
    final darkContrastEnabled = darkContrast.enabled;

    return Scaffold(
      backgroundColor: darkContrastEnabled
          ? DarkContrastPalette.background
          : const Color(0xFFF2F5ED),
      appBar: AppBar(
        toolbarHeight: _HomeLayoutTokens.appBarHeight,
        backgroundColor: darkContrastEnabled
            ? DarkContrastPalette.surface
            : Colors.white,
        foregroundColor: darkContrastEnabled
            ? DarkContrastPalette.text
            : Colors.black87,
        leadingWidth: 56,
        leading: UserLogoMenuButton(
          size: 36,
          onPressed: () =>
              Navigator.pushNamed(context, UserSettingsRoutes.settings),
        ),
        title: const Text(
          'SaveTep',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: darkContrastEnabled
                ? 'Disable Dark Contrast'
                : 'Enable Dark Contrast',
            icon: Icon(
              darkContrastEnabled ? Icons.dark_mode : Icons.dark_mode_outlined,
              size: 24,
            ),
            onPressed: () => unawaited(darkContrast.toggle()),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 24),
            onPressed: () async {
              await AuthService.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
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
            onRefresh: _loadBudgetData,
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
                      height: metrics.contentHeight(featureCount),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: metrics.topPadding),
                          _buildDateRangePill(metrics, darkContrastEnabled),
                          SizedBox(height: metrics.compactSectionGap),
                          _HomeDateRangeSelector(
                            metrics: metrics,
                            darkContrastEnabled: darkContrastEnabled,
                            selectedPeriod: _selectedPeriod,
                            selectedMonth: _selectedMonth,
                            selectedQuarter: _selectedQuarter,
                            availableMonths:
                                _HomeDateRangeService.availableMonthOptions(
                                  AppClock.now,
                                ),
                            availableQuarters:
                                _HomeDateRangeService.availableQuarterOptions(
                                  AppClock.now,
                                ),
                            onPeriodSelected: _selectPeriod,
                            onMonthSelected: _selectMonth,
                            onQuarterSelected: _selectQuarter,
                          ),
                          SizedBox(height: metrics.sectionGap),
                          _buildBudgetSection(metrics, featureCount),
                          SizedBox(height: metrics.sectionGap),
                          Expanded(
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
    if (_isLoadingBudget) {
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

    return SizedBox(
      width: double.infinity,
      height: sectionHeight,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: metrics.contentWidth,
          child: BudgetDonutChart(
            data: _budgetData,
            periodKey: _selectedPeriod.label,
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangePill(
    _HomeLayoutMetrics metrics,
    bool darkContrastEnabled,
  ) {
    final periodLabel = _budgetData.period.isEmpty
        ? '${_formatDate(_startDate)} - ${_formatDate(_endDate)}'
        : _budgetData.period;

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
        color: darkContrastEnabled
            ? DarkContrastPalette.elevatedSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: darkContrastEnabled
              ? DarkContrastPalette.border
              : const Color(0xFFD7DEC9),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: iconSize,
            color: darkContrastEnabled
                ? DarkContrastPalette.primary
                : const Color(0xFF0E5E54),
          ),
          SizedBox(width: iconGap),
          Expanded(
            child: Text(
              periodLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: darkContrastEnabled
                    ? DarkContrastPalette.text
                    : const Color(0xFF173E37),
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

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _HomeDateRangeSelector extends StatelessWidget {
  final _HomeLayoutMetrics metrics;
  final bool darkContrastEnabled;
  final _HomePeriodType selectedPeriod;
  final int selectedMonth;
  final int selectedQuarter;
  final List<_MonthOption> availableMonths;
  final List<_QuarterOption> availableQuarters;
  final ValueChanged<_HomePeriodType> onPeriodSelected;
  final ValueChanged<int> onMonthSelected;
  final ValueChanged<int> onQuarterSelected;

  const _HomeDateRangeSelector({
    required this.metrics,
    required this.darkContrastEnabled,
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
    final List<_HomePeriodType> periods = _HomePeriodType.values;
    return Row(
      children: <Widget>[
        for (int index = 0; index < periods.length; index += 1) ...<Widget>[
          Expanded(child: _buildPeriodSegment(periods[index])),
          if (index < periods.length - 1) SizedBox(width: metrics.tabGap),
        ],
      ],
    );
  }

  Widget _buildPeriodSegment(_HomePeriodType period) {
    return switch (period) {
      _HomePeriodType.month => _PeriodMenuAnchor<_MonthOption>(
        period: period,
        options: availableMonths,
        optionLabel: (_MonthOption option) => option.label,
        isOptionSelected: (_MonthOption option) =>
            option.month == selectedMonth,
        onOptionSelected: (_MonthOption option) =>
            onMonthSelected(option.month),
        onPeriodSelected: onPeriodSelected,
        buttonBuilder: (VoidCallback onPressed) {
          return _HomePeriodButton(
            label: period.label,
            detail: selectedPeriod == period
                ? _monthNames[selectedMonth]
                : null,
            isSelected: selectedPeriod == period,
            metrics: metrics,
            darkContrastEnabled: darkContrastEnabled,
            onPressed: onPressed,
          );
        },
      ),
      _HomePeriodType.quarter => _PeriodMenuAnchor<_QuarterOption>(
        period: period,
        options: availableQuarters,
        optionLabel: (_QuarterOption option) => option.label,
        isOptionSelected: (_QuarterOption option) =>
            option.quarter == selectedQuarter,
        onOptionSelected: (_QuarterOption option) =>
            onQuarterSelected(option.quarter),
        onPeriodSelected: onPeriodSelected,
        buttonBuilder: (VoidCallback onPressed) {
          return _HomePeriodButton(
            label: period.label,
            detail: selectedPeriod == period ? 'Q$selectedQuarter' : null,
            isSelected: selectedPeriod == period,
            metrics: metrics,
            darkContrastEnabled: darkContrastEnabled,
            onPressed: onPressed,
          );
        },
      ),
      _ => _HomePeriodButton(
        label: period.label,
        isSelected: selectedPeriod == period,
        metrics: metrics,
        darkContrastEnabled: darkContrastEnabled,
        onPressed: () => onPeriodSelected(period),
      ),
    };
  }
}

class _PeriodMenuAnchor<T> extends StatelessWidget {
  final _HomePeriodType period;
  final List<T> options;
  final String Function(T option) optionLabel;
  final bool Function(T option) isOptionSelected;
  final ValueChanged<T> onOptionSelected;
  final ValueChanged<_HomePeriodType> onPeriodSelected;
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
  final bool darkContrastEnabled;
  final VoidCallback? onPressed;

  const _HomePeriodButton({
    required this.label,
    this.detail,
    required this.isSelected,
    required this.metrics,
    required this.darkContrastEnabled,
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
          backgroundColor: isSelected
              ? (darkContrastEnabled
                    ? DarkContrastPalette.primary
                    : const Color(0xFF075E54))
              : (darkContrastEnabled
                    ? DarkContrastPalette.elevatedSurface
                    : Colors.white),
          foregroundColor: isSelected
              ? (darkContrastEnabled ? Colors.black : Colors.white)
              : (darkContrastEnabled
                    ? DarkContrastPalette.text
                    : const Color(0xFF173E37)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: isSelected
              ? BorderSide.none
              : BorderSide(
                  color: darkContrastEnabled
                      ? DarkContrastPalette.border
                      : const Color(0xFFD7DEC9),
                  width: 1,
                ),
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
