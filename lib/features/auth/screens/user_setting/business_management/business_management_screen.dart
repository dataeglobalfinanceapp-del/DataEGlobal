import 'package:flutter/material.dart';

import '../widgets/user_setting_detail_scaffold.dart';

class BusinessManagementScreen extends StatelessWidget {
  const BusinessManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserSettingDetailScaffold(
      title: 'Business Management',
      icon: Icons.person,
      accentColor: Color(0xFF38A9E8),
    );
  }
}
