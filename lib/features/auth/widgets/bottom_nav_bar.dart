import 'package:flutter/material.dart';

import '../screens/user_setting/user_settings_routes.dart';
import 'app_bottom_navigation_bar.dart';

export 'app_bottom_navigation_bar.dart';

bool isAuthBottomNavRoute(String? routeName) {
  switch (routeName) {
    case Navigator.defaultRouteName:
    case '/login':
    case '/signup':
    case '/confirm-signup':
    case '/forgot-password':
    case '/confirm-reset':
      return true;
  }

  return false;
}

AppBottomNavItem? bottomNavItemForRouteName(
  String? routeName, {
  AppBottomNavItem? fallback,
}) {
  if (routeName == null) return fallback;
  if (isAuthBottomNavRoute(routeName)) return null;

  switch (routeName) {
    case '/reminders':
      return AppBottomNavItem.calendar;
    case '/transactions':
    case '/tax':
      return AppBottomNavItem.report;
    case UserSettingsRoutes.settings:
    case UserSettingsRoutes.businessManagement:
    case UserSettingsRoutes.enterpriseCodeId:
    case UserSettingsRoutes.changePassword:
    case UserSettingsRoutes.institutionSupport:
    case UserSettingsRoutes.managePartner:
    case UserSettingsRoutes.deactivateAccess:
      return AppBottomNavItem.settings;
    case '/home':
    case '/scan':
    case '/scan-deposit':
    case '/scan-expense':
    case '/liabilities':
    case '/saving':
    case '/payroll':
      return AppBottomNavItem.home;
  }

  return null;
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const BottomNavBar({super.key, this.currentIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isAuthBottomNavRoute(ModalRoute.of(context)?.settings.name)) {
      return const SizedBox.shrink();
    }

    final items = AppBottomNavItem.values;
    final selectedIndex = currentIndex.clamp(0, items.length - 1).toInt();
    final currentItem = items[selectedIndex];

    return AppBottomNavigationBar(
      currentItem: currentItem,
      onItemSelected: onTap == null
          ? null
          : (item) => onTap!(items.indexOf(item)),
    );
  }
}
