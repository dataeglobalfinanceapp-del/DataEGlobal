import 'package:flutter_test/flutter_test.dart';

import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/screens/user_settings/business_management/business_profile_form_controller.dart';

void main() {
  test(
    'BusinessProfileFormController validates and normalizes submissions',
    () async {
      const profile = BusinessProfile(
        businessName: ' Sunny Nails ',
        dba: ' Sunny Spa ',
        address: ' 123 Main Street ',
        ein: ' 12-3456789 ',
        email: ' owner@example.com ',
        phone: ' 714-555-0100 ',
        setupCompleted: true,
      );
      final controller = BusinessProfileFormController(profile);
      addTearDown(controller.dispose);
      BusinessProfile? savedProfile;

      final result = await controller.submit((profile) async {
        savedProfile = profile;
      });

      expect(result, BusinessProfileSubmission.saved);
      expect(savedProfile?.businessName, 'Sunny Nails');
      expect(savedProfile?.email, 'owner@example.com');
      expect(savedProfile?.setupCompleted, isFalse);
    },
  );
}
