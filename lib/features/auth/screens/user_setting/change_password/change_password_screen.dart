import 'package:flutter/material.dart';

import '../widgets/user_setting_detail_scaffold.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserSettingDetailScaffold(
      title: 'Change Password',
      icon: Icons.lock,
      accentColor: Color(0xFF2563EB),
    );
  }
}
