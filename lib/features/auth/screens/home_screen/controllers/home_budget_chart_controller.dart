import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:savetep/features/auth/screens/home_screen/domain/home_budget_chart_calculator.dart';
import 'package:savetep/features/auth/screens/home_screen/repositories/home_budget_target_repository.dart';

class HomeBudgetChartController extends ChangeNotifier {
  final HomeBudgetTargetRepository _repository;

  final Map<String, Map<String, double>> _targetPercentagesByPeriod = {};
  bool _isEditingTargets = false;
  bool _isDisposed = false;

  HomeBudgetChartController({HomeBudgetTargetRepository? repository})
    : _repository = repository ?? const ServiceHomeBudgetTargetRepository();

  bool get isEditingTargets => _isEditingTargets;

  Map<String, double> targetPercentagesFor(String periodKey) {
    return _targetPercentagesByPeriod[periodKey] ?? const <String, double>{};
  }

  Future<void> loadTargets() async {
    final targets = await _repository.loadTargetPercentages();
    if (_isDisposed) return;
    _targetPercentagesByPeriod
      ..clear()
      ..addAll(targets);
    notifyListeners();
  }

  void toggleEditingTargets() {
    _isEditingTargets = !_isEditingTargets;
    notifyListeners();
  }

  void updateTarget({
    required String periodKey,
    required String label,
    required String value,
  }) {
    final target = HomeBudgetChartCalculator.targetPercentageFrom(value);
    final periodTargets = _targetPercentagesByPeriod.putIfAbsent(
      periodKey,
      () => <String, double>{},
    );
    if (target == null) {
      periodTargets.remove(label);
    } else {
      periodTargets[label] = target;
    }
    notifyListeners();
    unawaited(_saveTargets());
  }

  Future<void> _saveTargets() {
    return _repository.saveTargetPercentages(_targetPercentagesByPeriod);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
