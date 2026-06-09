import 'package:flutter/material.dart';

class UserLogoMenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  const UserLogoMenuButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Center(
        child: Tooltip(
          message: 'User settings',
          child: Semantics(
            label: 'Open user settings',
            button: true,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: Ink(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD8ECFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 8,
                        child: CircleAvatar(
                          radius: 7,
                          backgroundColor: Color(0xFF334155),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFF3B82C4),
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
