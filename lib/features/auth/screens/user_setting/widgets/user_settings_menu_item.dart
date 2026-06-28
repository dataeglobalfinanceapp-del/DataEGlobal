import 'package:flutter/material.dart';

class UserSettingsMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final VoidCallback onTap;

  const UserSettingsMenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final darkContrastEnabled = Theme.of(context).brightness == Brightness.dark;
    final textColor = darkContrastEnabled
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF202124);
    final chevronColor = darkContrastEnabled
        ? const Color(0xFFC7D2E3)
        : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: chevronColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
