import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/screens/user_settings/user_settings_controller.dart';

void main() {
  test(
    'UserSettingsController signs out before clearing profile state',
    () async {
      final events = <String>[];
      final controller = UserSettingsController(
        signOutRequest: () async => events.add('signed-out'),
        clearBusinessProfile: () => events.add('profile-cleared'),
      );

      await controller.signOut();

      expect(events, ['signed-out', 'profile-cleared']);
    },
  );
}
