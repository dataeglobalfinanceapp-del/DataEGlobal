import 'package:flutter/foundation.dart';

import 'package:savetep/features/auth/screens/home_screen/domain/home_budget_data_mapper.dart';
import 'package:savetep/features/auth/screens/home_screen/models/home_budget_chart_models.dart';
import 'package:savetep/services/liability_service.dart';

abstract interface class HomeBudgetRepository {
  ValueListenable<int> get dataVersion;

  Future<HomeBudgetData> loadBudgetData({
    required DateTime startDate,
    required DateTime endDate,
    required String period,
  });
}

class LiabilityHomeBudgetRepository implements HomeBudgetRepository {
  const LiabilityHomeBudgetRepository();

  @override
  ValueListenable<int> get dataVersion => LiabilityService.dataVersion;

  @override
  Future<HomeBudgetData> loadBudgetData({
    required DateTime startDate,
    required DateTime endDate,
    required String period,
  }) async {
    final data = await LiabilityService.loadBudgetData(
      startDate: startDate,
      endDate: endDate,
      period: period,
    );
    return mapHomeBudgetData(data);
  }
}
