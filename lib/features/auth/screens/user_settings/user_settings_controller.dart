import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/providers/auth_provider.dart';
import 'package:savetep/providers/business_profile_provider.dart';

final userSettingsControllerProvider = Provider<UserSettingsController>((ref) {
  return UserSettingsController(
    signOutRequest: () => ref.read(authStateProvider.notifier).signOut(),
    clearBusinessProfile: () => ref.invalidate(businessProfileProvider),
  );
});

typedef UserSettingsSignOutRequest = Future<void> Function();

class UserSettingsController {
  final UserSettingsSignOutRequest _signOutRequest;
  final void Function() _clearBusinessProfile;

  const UserSettingsController({
    required UserSettingsSignOutRequest signOutRequest,
    required void Function() clearBusinessProfile,
  }) : _signOutRequest = signOutRequest,
       _clearBusinessProfile = clearBusinessProfile;

  Future<void> signOut() async {
    await _signOutRequest();
    _clearBusinessProfile();
  }
}
