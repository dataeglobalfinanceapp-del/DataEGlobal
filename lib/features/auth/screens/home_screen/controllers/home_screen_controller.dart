import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:savetep/features/auth/screens/home_screen/models/home_budget_chart_models.dart';
import 'package:savetep/features/auth/screens/home_screen/models/home_date_range.dart';
import 'package:savetep/features/auth/screens/home_screen/repositories/home_budget_repository.dart';
import 'package:savetep/features/auth/screens/home_screen/services/home_customer_service.dart';
import 'package:savetep/services/app_clock.dart';

typedef HomeNow = DateTime Function();

class HomeScreenController extends ChangeNotifier {
  final HomeBudgetRepository _budgetRepository;
  final HomeCustomerService _customerService;
  final HomeNow _now;

  HomePeriodType _selectedPeriod = HomePeriodType.week;
  late int _selectedMonth;
  late int _selectedQuarter;
  late HomeDateRange _dateRange;
  HomeBudgetData _budgetData = const HomeBudgetData();
  bool _isLoadingBudget = true;
  bool _isStarted = false;
  bool _isDisposed = false;
  int _budgetLoadSerial = 0;

  HomeScreenController({
    HomeBudgetRepository? budgetRepository,
    HomeCustomerService? customerService,
    HomeNow? now,
  }) : _budgetRepository =
           budgetRepository ?? const LiabilityHomeBudgetRepository(),
       _customerService =
           customerService ?? const LauncherHomeCustomerService(),
       _now = now ?? _appNow {
    final today = _now();
    _selectedMonth = today.month;
    _selectedQuarter = HomeDateRangeCalculator.currentQuarter(today);
    _updateDateRange();
  }

  HomePeriodType get selectedPeriod => _selectedPeriod;
  int get selectedMonth => _selectedMonth;
  int get selectedQuarter => _selectedQuarter;
  DateTime get startDate => _dateRange.start;
  DateTime get endDate => _dateRange.end;
  HomeBudgetData get budgetData => _budgetData;
  bool get isLoadingBudget => _isLoadingBudget;

  String get dateRangeLabel {
    if (_budgetData.period.isNotEmpty) return _budgetData.period;
    return _formatRange(_dateRange);
  }

  List<HomeMonthOption> get availableMonths {
    return HomeDateRangeCalculator.availableMonthOptions(_now());
  }

  List<HomeQuarterOption> get availableQuarters {
    return HomeDateRangeCalculator.availableQuarterOptions(_now());
  }

  void start() {
    if (_isStarted) return;
    _isStarted = true;
    _budgetRepository.dataVersion.addListener(_handleBudgetDataChanged);
    unawaited(loadBudgetData());
  }

  Future<void> loadBudgetData() async {
    final loadSerial = ++_budgetLoadSerial;
    _updateDateRange();
    _isLoadingBudget = true;
    notifyListeners();

    final range = _dateRange;
    final data = await _budgetRepository.loadBudgetData(
      startDate: range.start,
      endDate: range.end,
      period: _formatRange(range),
    );

    if (_isDisposed || loadSerial != _budgetLoadSerial) return;
    _budgetData = data;
    _isLoadingBudget = false;
    notifyListeners();
  }

  void selectPeriod(HomePeriodType period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    _updateDateRange();
    unawaited(loadBudgetData());
  }

  void selectMonth(int month) {
    final availableMonth = HomeDateRangeCalculator.clampMonth(month, _now());
    if (_selectedPeriod == HomePeriodType.month &&
        _selectedMonth == availableMonth) {
      return;
    }

    _selectedPeriod = HomePeriodType.month;
    _selectedMonth = availableMonth;
    _updateDateRange();
    unawaited(loadBudgetData());
  }

  void selectQuarter(int quarter) {
    final availableQuarter = HomeDateRangeCalculator.clampQuarter(
      quarter,
      _now(),
    );
    if (_selectedPeriod == HomePeriodType.quarter &&
        _selectedQuarter == availableQuarter) {
      return;
    }

    _selectedPeriod = HomePeriodType.quarter;
    _selectedQuarter = availableQuarter;
    _updateDateRange();
    unawaited(loadBudgetData());
  }

  Future<bool> callCustomerService() => _customerService.call();

  void _handleBudgetDataChanged() {
    if (_isDisposed) return;
    unawaited(loadBudgetData());
  }

  void _updateDateRange() {
    final today = _now();
    _selectedMonth = HomeDateRangeCalculator.clampMonth(_selectedMonth, today);
    _selectedQuarter = HomeDateRangeCalculator.clampQuarter(
      _selectedQuarter,
      today,
    );
    _dateRange = HomeDateRangeCalculator.rangeFor(
      period: _selectedPeriod,
      selectedMonth: _selectedMonth,
      selectedQuarter: _selectedQuarter,
      today: today,
    );
  }

  String _formatRange(HomeDateRange range) {
    return '${HomeDateRangeCalculator.formatDate(range.start)} - '
        '${HomeDateRangeCalculator.formatDate(range.end)}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_isStarted) {
      _budgetRepository.dataVersion.removeListener(_handleBudgetDataChanged);
    }
    super.dispose();
  }

  static DateTime _appNow() => AppClock.now;
}
