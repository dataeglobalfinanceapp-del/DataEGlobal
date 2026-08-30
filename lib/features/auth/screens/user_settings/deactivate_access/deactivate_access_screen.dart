import 'package:flutter/material.dart';

import '../widgets/user_settings_detail_scaffold.dart';

class DeactivateAccessScreen extends StatelessWidget {
  const DeactivateAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserSettingsDetailScaffold(
      title: 'Deactivate Access',
      icon: Icons.flash_on,
      accentColor: Color(0xFFDC2626),
    );
  }
}
