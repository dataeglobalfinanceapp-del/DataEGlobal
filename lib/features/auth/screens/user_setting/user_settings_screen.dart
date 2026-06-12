import 'package:flutter/material.dart';

import '../../widgets/app_bottom_navigation_bar.dart';
import 'user_settings_routes.dart';
import 'widgets/user_settings_menu_item.dart';

class UserSettingsScreen extends StatelessWidget {
  const UserSettingsScreen({super.key});

  static const List<_UserSettingsMenuDestination> _destinations = [
    _UserSettingsMenuDestination(
      title: 'Business Management',
      routeName: UserSettingsRoutes.businessManagement,
      icon: Icons.person,
      iconColor: Color(0xFF38A9E8),
      iconBackgroundColor: Color(0xFFE0F2FE),
    ),
    _UserSettingsMenuDestination(
      title: 'Enterprise Code ID',
      routeName: UserSettingsRoutes.enterpriseCodeId,
      icon: Icons.qr_code_2,
      iconColor: Color(0xFF7C3AED),
      iconBackgroundColor: Color(0xFFEDE9FE),
    ),
    _UserSettingsMenuDestination(
      title: 'Change Password',
      routeName: UserSettingsRoutes.changePassword,
      icon: Icons.lock,
      iconColor: Color(0xFF2563EB),
      iconBackgroundColor: Color(0xFFDBEAFE),
    ),
    _UserSettingsMenuDestination(
      title: 'Institution Support',
      routeName: UserSettingsRoutes.institutionSupport,
      icon: Icons.handshake_outlined,
      iconColor: Color(0xFFF59E0B),
      iconBackgroundColor: Color(0xFFFEF3C7),
    ),
    _UserSettingsMenuDestination(
      title: 'Manage partner',
      routeName: UserSettingsRoutes.managePartner,
      icon: Icons.groups_2,
      iconColor: Color(0xFF6366F1),
      iconBackgroundColor: Color(0xFFE0E7FF),
    ),
    _UserSettingsMenuDestination(
      title: 'Deactivate Access',
      routeName: UserSettingsRoutes.deactivateAccess,
      icon: Icons.flash_on,
      iconColor: Color(0xFFDC2626),
      iconBackgroundColor: Color(0xFFFEE2E2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF202124),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentItem: AppBottomNavItem.settings,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            const Text(
              'Account',
              style: TextStyle(
                color: Color(0xFF202124),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (final destination in _destinations)
                    UserSettingsMenuItem(
                      title: destination.title,
                      icon: destination.icon,
                      iconColor: destination.iconColor,
                      iconBackgroundColor: destination.iconBackgroundColor,
                      onTap: () =>
                          Navigator.pushNamed(context, destination.routeName),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSettingsMenuDestination {
  final String title;
  final String routeName;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;

  const _UserSettingsMenuDestination({
    required this.title,
    required this.routeName,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
  });
}
