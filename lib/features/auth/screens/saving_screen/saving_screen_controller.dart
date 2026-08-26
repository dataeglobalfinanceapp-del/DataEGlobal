import 'package:flutter/foundation.dart';

import 'package:savetep/features/auth/screens/saving_screen/saving_plan_calculator.dart';
import 'package:savetep/features/auth/screens/saving_screen/saving_repository.dart';
import 'package:savetep/features/auth/screens/saving_screen/saving_screen_models.dart';
import 'package:savetep/services/app_clock.dart';

typedef SavingNow = DateTime Function();

class SavingScreenController extends ChangeNotifier {
  static const double defaultSavingRate = 10;

  final SavingDepositRepository _repository;
  final SavingNow _now;

  SavingPeriod _period = SavingPeriod.month;
  late int _year;
  double _savingRate = defaultSavingRate;
  bool _showPastPeriods = false;
  bool _isLoading = true;
  bool _isDisposed = false;
  List<SavingDeposit> _deposits = const [];
  Map<DateTime, double> _dailySavedAmounts = const {};

  SavingScreenController({SavingDepositRepository? repository, SavingNow? now})
    : _repository = repository ?? const LiabilitySavingDepositRepository(),
      _now = now ?? _appNow {
    _year = _now().year;
  }

  SavingPeriod get period => _period;
  int get year => _year;
  double get savingRate => _savingRate;
  bool get showPastPeriods => _showPastPeriods;
  bool get isLoading => _isLoading;
  DateTime get today => SavingPlanCalculator.dateOnly(_now());

  double get totalDeposit => _deposits
      .where((deposit) => deposit.date.year == _year)
      .fold<double>(0, (sum, deposit) => sum + deposit.amount);

  double get totalSavingTarget => totalDeposit * (_savingRate / 100);

  double get totalSaving =>
      _dailySavedAmounts.values.fold<double>(0, (sum, amount) => sum + amount);

  List<SavingPeriodRow> get savingRows => SavingPlanCalculator.buildRows(
    period: _period,
    year: _year,
    totalTarget: totalSavingTarget,
    dailySavedAmounts: _dailySavedAmounts,
    today: today,
  );

  List<SavingPeriodRow> visibleRows(List<SavingPeriodRow> rows) {
    return SavingPlanCalculator.visibleRows(
      rows: rows,
      today: today,
      showPastPeriods: _showPastPeriods,
    );
  }

  List<SavingPeriodRow> pastRows(List<SavingPeriodRow> rows) {
    return SavingPlanCalculator.pastRows(rows: rows, today: today);
  }

  double periodTarget(List<SavingPeriodRow> rows) {
    final dueRows = rows.where(
      (row) => !SavingPlanCalculator.isPast(row, today),
    );
    return dueRows.isEmpty
        ? (rows.isEmpty ? 0.0 : rows.first.requiredAmount)
        : dueRows.first.requiredAmount;
  }

  double savedAmountFor(SavingPeriodRow row) {
    return SavingPlanCalculator.savedAmountInRange(
      _dailySavedAmounts,
      row.start,
      row.end,
    );
  }

  double remainingAmountFor(SavingPeriodRow row) {
    final remainingAmount = row.requiredAmount - savedAmountFor(row);
    return remainingAmount < 1 ? 0.0 : remainingAmount;
  }

  Future<void> loadData() async {
    if (!_isLoading) {
      _isLoading = true;
      notifyListeners();
    }
    final deposits = await _repository.loadDeposits();
    if (_isDisposed) return;

    _deposits = deposits;
    _isLoading = false;
    notifyListeners();
  }

  void setPeriod(SavingPeriod period) {
    if (_period == period && !_showPastPeriods) return;
    _period = period;
    _showPastPeriods = false;
    notifyListeners();
  }

  void changeYear(int delta) {
    _year += delta;
    _showPastPeriods = false;
    notifyListeners();
  }

  void togglePastPeriods() {
    _showPastPeriods = !_showPastPeriods;
    notifyListeners();
  }

  void setSavingRate(double rate) {
    if (!SavingRateInput.isValid(rate)) return;
    if (_savingRate == rate) return;
    _savingRate = rate;
    notifyListeners();
  }

  void recordSavedAmount(SavingPeriodRow row, double amount) {
    _dailySavedAmounts = SavingPlanCalculator.recordSavedAmount(
      dailySavedAmounts: _dailySavedAmounts,
      start: row.start,
      end: row.end,
      amount: amount,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  static DateTime _appNow() => AppClock.now;
}
