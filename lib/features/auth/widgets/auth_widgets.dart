import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AuthTab { login, signup }

class AuthTokens {
  const AuthTokens._();

  static const Color screenBackground = Color(0xFFF5F5F5);
  static const Color primary = Color(0xFF1A2340);
  static const Color textStrong = Color(0xFF222222);
  static const Color textMuted = Color(0xFF555555);
  static const Color textSubtle = Color(0xFF888888);
  static const Color textPlaceholder = Color(0xFFAAAAAA);
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFD8D8D8);
  static const Color tabBackground = Color(0xFFE8E8E8);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorBorder = Color(0xFFFCA5A5);
  static const Color errorSurface = Color(0xFFFFF5F5);
  static const Color surface = Colors.white;

  static const double contentMaxWidth = 420;
  static const double logoSize = 56;
  static const double controlHeight = 52;
  static const double socialButtonHeight = 50;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets fieldPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius controlRadius = BorderRadius.all(
    Radius.circular(10),
  );
  static const BorderRadius logoRadius = BorderRadius.all(Radius.circular(14));

  static const TextStyle brandTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: primary,
  );
  static const TextStyle brandSubtitle = TextStyle(
    fontSize: 13,
    color: textSubtle,
  );
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: textMuted,
  );
  static const TextStyle fieldHint = TextStyle(
    color: textPlaceholder,
    fontSize: 14,
  );
  static const TextStyle primaryButtonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodySmall = TextStyle(fontSize: 13, color: textMuted);
  static const TextStyle link = TextStyle(
    color: primary,
    decoration: TextDecoration.underline,
    fontSize: 13,
  );
  static const TextStyle socialLabel = TextStyle(
    fontSize: 14,
    color: textStrong,
  );
}

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
    hintStyle: AuthTokens.fieldHint,
    suffixIcon: suffix,
    filled: true,
    fillColor: AuthTokens.surface,
    contentPadding: AuthTokens.fieldPadding,
    enabledBorder: OutlineInputBorder(
      borderRadius: AuthTokens.fieldRadius,
      borderSide: BorderSide(
        color: invalid ? AuthTokens.error : AuthTokens.border,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AuthTokens.fieldRadius,
      borderSide: BorderSide(
        color: invalid ? AuthTokens.error : AuthTokens.primary,
        width: 1.5,
      ),
    ),
  );
}

class AuthScreenScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final AuthTab activeTab;
  final VoidCallback? onLoginTap;
  final VoidCallback? onSignUpTap;
  final List<Widget> children;

  const AuthScreenScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activeTab,
    required this.children,
    this.onLoginTap,
    this.onSignUpTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTokens.screenBackground,
      appBar: AppBar(
        backgroundColor: AuthTokens.screenBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: AuthTokens.pagePadding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AuthTokens.contentMaxWidth,
              ),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 8),
                  AuthBrandHeader(title: title, subtitle: subtitle),
                  const SizedBox(height: 24),
                  AuthTabBar(
                    activeTab: activeTab,
                    onLoginTap: onLoginTap,
                    onSignUpTap: onSignUpTap,
                  ),
                  const SizedBox(height: 20),
                  ...children,
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Semantics(
          label: 'Save Tep logo',
          image: true,
          child: Container(
            width: AuthTokens.logoSize,
            height: AuthTokens.logoSize,
            decoration: const BoxDecoration(
              color: AuthTokens.primary,
              borderRadius: AuthTokens.logoRadius,
            ),
            child: const Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(title, style: AuthTokens.brandTitle),
        const SizedBox(height: 4),
        Text(subtitle, style: AuthTokens.brandSubtitle),
      ],
    );
  }
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
      decoration: const BoxDecoration(
        color: AuthTokens.tabBackground,
        borderRadius: AuthTokens.controlRadius,
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: <Widget>[
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
      child: Semantics(
        selected: isActive,
        button: true,
        child: Material(
          color: isActive ? AuthTokens.primary : Colors.transparent,
          borderRadius: AuthTokens.fieldRadius,
          child: InkWell(
            borderRadius: AuthTokens.fieldRadius,
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : AuthTokens.textMuted,
                ),
              ),
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
          style: AuthTokens.fieldLabel,
          children: <InlineSpan>[
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AuthTokens.error),
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
        color: AuthTokens.errorSurface,
        border: Border.all(color: AuthTokens.errorBorder),
        borderRadius: AuthTokens.controlRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.error_outline, color: AuthTokens.error, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please review the following:',
                  style: TextStyle(
                    color: AuthTokens.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.map(
            (String error) => Padding(
              padding: const EdgeInsets.only(left: 4, top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    '* ',
                    style: TextStyle(color: AuthTokens.errorDark, fontSize: 13),
                  ),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: AuthTokens.errorDark,
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

class AuthTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool invalid;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AuthTextInput({
    super.key,
    required this.controller,
    required this.hint,
    this.invalid = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.inputFormatters,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: authFieldDecoration(hint: hint, invalid: invalid),
    );
  }
}

class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final bool invalid;
  final VoidCallback onToggleVisibility;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    this.invalid = false,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofillHints: const <String>[AutofillHints.password],
      decoration: authFieldDecoration(
        hint: '************',
        invalid: invalid,
        suffix: IconButton(
          tooltip: obscureText ? 'Show password' : 'Hide password',
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AuthTokens.controlHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthTokens.primary,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: AuthTokens.controlRadius,
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label, style: AuthTokens.primaryButtonLabel),
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
      height: AuthTokens.socialButtonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AuthTokens.border),
          backgroundColor: AuthTokens.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AuthTokens.controlRadius,
          ),
        ),
        child: child,
      ),
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(child: Divider(color: AuthTokens.divider)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or',
            style: TextStyle(color: AuthTokens.textSubtle, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AuthTokens.divider)),
      ],
    );
  }
}

class AuthAccountSwitchLink extends StatelessWidget {
  final String text;
  final String actionLabel;
  final VoidCallback onPressed;

  const AuthAccountSwitchLink({
    super.key,
    required this.text,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(text, style: AuthTokens.bodySmall),
        TextButton(
          onPressed: onPressed,
          child: Text(
            actionLabel,
            style: AuthTokens.link.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class AuthCountryCodeButton extends StatelessWidget {
  final String countryCode;
  final bool invalid;
  final VoidCallback onPressed;

  const AuthCountryCodeButton({
    super.key,
    required this.countryCode,
    required this.invalid,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: BorderSide(
            color: invalid ? AuthTokens.error : AuthTokens.border,
          ),
          backgroundColor: AuthTokens.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AuthTokens.fieldRadius,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              countryCode,
              style: const TextStyle(
                fontSize: 14,
                color: AuthTokens.textStrong,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AuthTokens.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

class AuthGoogleIcon extends StatelessWidget {
  const AuthGoogleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    void drawArc(Color color, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        Paint()..color = color,
      );
    }

    const double pi = 3.14159265;
    drawArc(const Color(0xFF4285F4), -pi / 2, pi);
    drawArc(const Color(0xFF34A853), pi / 2, pi / 2);
    drawArc(const Color(0xFFFBBC05), pi, pi / 2);
    drawArc(const Color(0xFFEA4335), -pi / 2, -pi / 2);

    canvas.drawCircle(center, radius * 0.65, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(radius, radius - radius * 0.18, radius, radius * 0.36),
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawRect(
      Rect.fromLTWH(radius, radius - radius * 0.18, radius, radius * 0.36),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
