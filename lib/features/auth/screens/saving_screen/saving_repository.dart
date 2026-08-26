import 'package:savetep/features/auth/screens/saving_screen/saving_screen_models.dart';
import 'package:savetep/services/liability_service.dart';

abstract interface class SavingDepositRepository {
  Future<List<SavingDeposit>> loadDeposits();
}

class LiabilitySavingDepositRepository implements SavingDepositRepository {
  const LiabilitySavingDepositRepository();

  @override
  Future<List<SavingDeposit>> loadDeposits() async {
    final deposits = await LiabilityService.loadDeposits();
    return [
      for (final deposit in deposits)
        SavingDeposit(
          amount: deposit.totalAmount,
          date: deposit.transactionDate,
        ),
    ];
  }
}
