import 'dart:async';

import 'package:flutter/material.dart';
import 'package:savetep/theme/dark_contrast.dart';

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
    final darkContrast = DarkContrastScope.of(context);
    final darkContrastEnabled = darkContrast.enabled;
    final backgroundColor = darkContrastEnabled
        ? DarkContrastPalette.background
        : const Color(0xFFF5F5F5);
    final surfaceColor = darkContrastEnabled
        ? DarkContrastPalette.surface
        : Colors.white;
    final textColor = darkContrastEnabled
        ? DarkContrastPalette.text
        : const Color(0xFF202124);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: darkContrastEnabled
                ? DarkContrastPalette.text
                : Colors.black87,
          ),
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
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            _DarkContrastSettingsTile(
              enabled: darkContrastEnabled,
              surfaceColor: surfaceColor,
              textColor: textColor,
              onChanged: (value) => unawaited(darkContrast.setEnabled(value)),
            ),
            const SizedBox(height: 18),
            Text(
              'Account',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(4),
                border: darkContrastEnabled
                    ? Border.all(color: DarkContrastPalette.border)
                    : null,
                boxShadow: darkContrastEnabled
                    ? null
                    : const [
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

class _DarkContrastSettingsTile extends StatelessWidget {
  final bool enabled;
  final Color surfaceColor;
  final Color textColor;
  final ValueChanged<bool> onChanged;

  const _DarkContrastSettingsTile({
    required this.enabled,
    required this.surfaceColor,
    required this.textColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: enabled ? Border.all(color: DarkContrastPalette.border) : null,
        boxShadow: enabled
            ? null
            : const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: enabled
                      ? DarkContrastPalette.primary.withValues(alpha: 0.16)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  enabled ? Icons.dark_mode : Icons.dark_mode_outlined,
                  color: enabled
                      ? DarkContrastPalette.primary
                      : const Color(0xFF334155),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Dark Contrast',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch.adaptive(
              key: const ValueKey('settings.darkContrastSwitch'),
              value: enabled,
              onChanged: onChanged,
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
