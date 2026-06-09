import 'package:flutter/material.dart';

import '../widgets/user_setting_detail_scaffold.dart';

class DeactivateAccessScreen extends StatelessWidget {
  const DeactivateAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserSettingDetailScaffold(
      title: 'Deactivate Access',
      icon: Icons.flash_on,
      accentColor: Color(0xFFDC2626),
    );
  }
}
