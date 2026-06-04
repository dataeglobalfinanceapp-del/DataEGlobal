import 'package:flutter/material.dart';

enum AuthTab { login, signup }

class AuthFocusTraversal extends StatelessWidget {
  final Widget child;

  const AuthFocusTraversal({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: child,
    );
  }
}

InputDecoration authFieldDecoration({
  required String hint,
  bool invalid = false,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: invalid ? const Color(0xFFEF4444) : const Color(0xFFE0E0E0),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: invalid ? const Color(0xFFEF4444) : const Color(0xFF1A2340),
        width: 1.5,
      ),
    ),
  );
}

class AuthTabBar extends StatelessWidget {
  final AuthTab activeTab;
  final VoidCallback? onLoginTap;
  final VoidCallback? onSignUpTap;

  const AuthTabBar({
    super.key,
    required this.activeTab,
    this.onLoginTap,
    this.onSignUpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8E8),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _AuthTabSegment(
            label: 'Sign Up',
            isActive: activeTab == AuthTab.signup,
            onTap: activeTab == AuthTab.login ? onSignUpTap : null,
          ),
          _AuthTabSegment(
            label: 'Login',
            isActive: activeTab == AuthTab.login,
            onTap: activeTab == AuthTab.signup ? onLoginTap : null,
          ),
        ],
      ),
    );
  }
}

class _AuthTabSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _AuthTabSegment({
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1A2340) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white : const Color(0xFF555555),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const AuthFieldLabel({super.key, required this.text, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Color(0xFF555555),
          ),
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
          ],
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final List<String> errors;

  const AuthErrorBanner({super.key, required this.errors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text(
                'Please review the following:',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.map(
            (error) => Padding(
              padding: const EdgeInsets.only(left: 4, top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                  ),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthSocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const AuthSocialButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: child,
      ),
    );
  }
}
