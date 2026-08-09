import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/features/auth/models/account_profile.dart';
import 'package:savetep/features/auth/services/account_profile_service.dart';

final accountProfileRepositoryProvider = Provider<AccountProfileRepository>(
  (ref) => const AccountProfileService(),
);

final accountProfileProvider =
    AsyncNotifierProvider<AccountProfileController, AccountProfile>(
      AccountProfileController.new,
    );

class AccountProfileController extends AsyncNotifier<AccountProfile> {
  @override
  Future<AccountProfile> build() {
    return ref.watch(accountProfileRepositoryProvider).load();
  }

  Future<void> updateBusinessName(String? businessName) async {
    final previous = state.requireValue;
    final updated = previous.withBusinessName(businessName);
    state = AsyncValue.data(updated);

    try {
      await ref.read(accountProfileRepositoryProvider).save(updated);
    } on Object {
      state = AsyncValue.data(previous);
      rethrow;
    }
  }
}
