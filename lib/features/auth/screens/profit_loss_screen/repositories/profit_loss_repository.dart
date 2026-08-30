import 'package:savetep/services/liability_service.dart';

import '../models/profit_loss_models.dart';

abstract interface class ProfitLossRepository {
  Future<ProfitLossData> load();
}

class LiabilityProfitLossRepository implements ProfitLossRepository {
  const LiabilityProfitLossRepository();

  @override
  Future<ProfitLossData> load() async {
    final List<DepositRecord> deposits = await LiabilityService.loadDeposits();
    final List<ExpenseRecord> expenses = await LiabilityService.loadExpenses();
    return ProfitLossData(deposits: deposits, expenses: expenses);
  }
}
