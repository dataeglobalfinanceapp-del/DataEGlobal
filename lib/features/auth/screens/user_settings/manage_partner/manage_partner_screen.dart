import 'package:flutter/material.dart';

import '../widgets/user_settings_detail_scaffold.dart';

class ManagePartnerScreen extends StatelessWidget {
  const ManagePartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserSettingsDetailScaffold(
      title: 'Manage partner',
      icon: Icons.groups_2,
      accentColor: Color(0xFF6366F1),
    );
  }
}
