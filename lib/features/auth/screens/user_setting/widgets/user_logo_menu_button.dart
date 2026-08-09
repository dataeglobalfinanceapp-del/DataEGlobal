import 'package:flutter/material.dart';

class UserLogoMenuButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;

  const UserLogoMenuButton({
    super.key,
    required this.onPressed,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Center(
        child: Tooltip(
          message: 'Account',
          child: Semantics(
            label: 'Open Account Settings',
            button: true,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: Ink(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD8ECFF),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: size * 0.19,
                        child: CircleAvatar(
                          radius: size * 0.17,
                          backgroundColor: const Color(0xFF334155),
                        ),
                      ),
                      Positioned(
                        bottom: size * 0.14,
                        child: Icon(
                          Icons.person,
                          size: size * 0.72,
                          color: const Color(0xFF3B82C4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
