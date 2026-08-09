import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/services/business_profile_service.dart';

final businessProfileRepositoryProvider = Provider<BusinessProfileRepository>(
  (ref) => const BusinessProfileService(),
);

final businessProfileProvider =
    AsyncNotifierProvider<BusinessProfileController, BusinessProfile>(
      BusinessProfileController.new,
    );

class BusinessProfileController extends AsyncNotifier<BusinessProfile> {
  @override
  Future<BusinessProfile> build() {
    return ref.watch(businessProfileRepositoryProvider).load();
  }

  Future<BusinessProfile> save(BusinessProfile profile) async {
    final saved = await ref
        .read(businessProfileRepositoryProvider)
        .save(profile);
    state = AsyncValue.data(saved);
    return saved;
  }
}
