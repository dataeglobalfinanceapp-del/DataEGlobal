import 'package:flutter/material.dart';

import '../screens/user_settings/user_settings_routes.dart';

enum AppBottomNavItem {
  home('Home', Icons.home_rounded, '/home'),
  calendar('Calendar', Icons.calendar_month_outlined, '/reminders'),
  report('Report', Icons.bar_chart_rounded, '/transactions'),
  settings('Settings', Icons.settings_outlined, UserSettingsRoutes.settings);

  final String label;
  final IconData icon;
  final String routeName;

  const AppBottomNavItem(this.label, this.icon, this.routeName);
}

class AppBottomNavigationBar extends StatelessWidget {
  final AppBottomNavItem currentItem;
  final ValueChanged<AppBottomNavItem>? onItemSelected;

  const AppBottomNavigationBar({
    super.key,
    required this.currentItem,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isCompact = constraints.maxWidth < 360;
            final double barHeight = isCompact ? 70 : 72;
            final double iconSize = isCompact ? 21 : 22;
            final double labelSize = isCompact ? 10 : 10.5;
            final double selectedWidth = isCompact ? 66 : 86;
            const double selectedHeight = 48;
            final BorderRadius barRadius = BorderRadius.circular(18);

            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: barRadius,
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x5500110E),
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: barRadius,
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0xFF075C50),
                        Color(0xFF02382F),
                        Color(0xFF01241F),
                      ],
                    ),
                    border: Border.all(color: const Color(0xFF0C7567)),
                  ),
                  child: Row(
                    children: AppBottomNavItem.values
                        .map((item) {
                          return Expanded(
                            child: _BottomNavButton(
                              item: item,
                              isSelected: item == currentItem,
                              iconSize: iconSize,
                              labelSize: labelSize,
                              selectedWidth: selectedWidth,
                              selectedHeight: selectedHeight,
                              onTap: () => _navigate(context, item),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigate(BuildContext context, AppBottomNavItem item) {
    if (item == currentItem) return;
    if (onItemSelected != null) {
      onItemSelected!(item);
      return;
    }
    Navigator.pushReplacementNamed(context, item.routeName);
  }
}

class _BottomNavButton extends StatelessWidget {
  final AppBottomNavItem item;
  final bool isSelected;
  final double iconSize;
  final double labelSize;
  final double selectedWidth;
  final double selectedHeight;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.item,
    required this.isSelected,
    required this.iconSize,
    required this.labelSize,
    required this.selectedWidth,
    required this.selectedHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFFFFC64B);
    final Color inactiveColor = const Color(0xFFE7FFF7);
    final Color itemColor = isSelected ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0x33FFC64B),
        highlightColor: const Color(0x2200A98F),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: selectedWidth,
            height: selectedHeight,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0B6A59).withValues(alpha: 0.72)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color(0x77FFC64B))
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(item.icon, color: itemColor, size: iconSize),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: itemColor,
                      fontSize: labelSize,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
