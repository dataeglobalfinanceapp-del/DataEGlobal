import 'package:flutter/material.dart';

import '../widgets/user_settings_detail_scaffold.dart';

class InstitutionSupportScreen extends StatelessWidget {
  const InstitutionSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserSettingsDetailScaffold(
      title: 'Institution Support',
      icon: Icons.handshake_outlined,
      accentColor: Color(0xFFF59E0B),
    );
  }
}
