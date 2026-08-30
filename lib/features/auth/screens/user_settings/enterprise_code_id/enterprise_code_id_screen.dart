import 'package:flutter/material.dart';

import '../widgets/user_settings_detail_scaffold.dart';

class EnterpriseCodeIdScreen extends StatelessWidget {
  const EnterpriseCodeIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserSettingsDetailScaffold(
      title: 'Enterprise Code ID',
      icon: Icons.qr_code_2,
      accentColor: Color(0xFF7C3AED),
    );
  }
}
