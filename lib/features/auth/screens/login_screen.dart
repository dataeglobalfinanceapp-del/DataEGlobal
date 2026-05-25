import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading       = false;
  bool _obscurePassword = true;

  // Validation errors shown in the red banner
  List<String> _errors = [];

  // Whether a field has been flagged invalid (for red border)
  bool _emailInvalid    = false;
  bool _passwordInvalid = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool _validate() {
    final errors = <String>[];
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailOk = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!emailOk) errors.add('A valid email is required');

    // Amplify Cognito default: min 8 chars
    final passwordOk = password.length >= 8;
    if (!passwordOk) {
      errors.add(
        'Password must be at least 8 characters and include uppercase, lowercase, number, and special character (!@#\$%^&*)',
      );
    }

    setState(() {
      _errors          = errors;
      _emailInvalid    = !emailOk;
      _passwordInvalid = !passwordOk;
    });

    return errors.isEmpty;
  }

  // ── Sign-in ───────────────────────────────────────────────────────────────

  Future<void> _signIn() async {
    if (!_validate()) return;

    setState(() => _loading = true);
    try {
      final signedIn = await AuthService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      if (signedIn) Navigator.pushReplacementNamed(context, '/home');
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _errors = [e.toString()]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Shared input decoration ───────────────────────────────────────────────

  InputDecoration _fieldDecoration({
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Logo ──────────────────────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2340),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Savings Teps',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2340),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Executive Financial Portal',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 24),

              // ── Tab bar ───────────────────────────────────────────────────
              _TabBar(
                activeTab: _ActiveTab.login,
                onSignUpTap: () =>
                    Navigator.pushReplacementNamed(context, '/signup'),
              ),
              const SizedBox(height: 20),

              // ── Error banner ──────────────────────────────────────────────
              if (_errors.isNotEmpty) ...[
                _ErrorBanner(errors: _errors),
                const SizedBox(height: 16),
              ],

              // ── Email ─────────────────────────────────────────────────────
              _FieldLabel(text: 'EMAIL', required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: _fieldDecoration(
                  hint: 'e.g: sunny@gmail.com',
                  invalid: _emailInvalid,
                ),
              ),
              const SizedBox(height: 16),

              // ── Password ──────────────────────────────────────────────────
              _FieldLabel(text: 'PASSWORD', required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _fieldDecoration(
                  hint: '••••••••••••',
                  invalid: _passwordInvalid,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Forgot password ───────────────────────────────────────────
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/forgot-password'),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Color(0xFF1A2340),
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Login button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2340),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Divider ───────────────────────────────────────────────────
              const _OrDivider(),
              const SizedBox(height: 16),

              // ── Google ────────────────────────────────────────────────────
              _SocialButton(
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GoogleIcon(),
                    const SizedBox(width: 12),
                    const Text(
                      'Login with Google',
                      style: TextStyle(fontSize: 14, color: Color(0xFF222222)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Apple ─────────────────────────────────────────────────────
              _SocialButton(
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.apple, size: 22, color: Color(0xFF222222)),
                    SizedBox(width: 12),
                    Text(
                      'Login with Apple',
                      style: TextStyle(fontSize: 14, color: Color(0xFF222222)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Sign up link ──────────────────────────────────────────────
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                  children: [
                    const TextSpan(text: "Don't have an account. "),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/signup'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2340),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets (used by both Login and SignUp screens)
// ─────────────────────────────────────────────────────────────────────────────

enum _ActiveTab { login, signup }

class _TabBar extends StatelessWidget {
  final _ActiveTab activeTab;
  final VoidCallback onSignUpTap;

  const _TabBar({required this.activeTab, required this.onSignUpTap});

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
          _Tab(
            label: 'Sign Up',
            isActive: activeTab == _ActiveTab.signup,
            onTap: activeTab == _ActiveTab.login ? onSignUpTap : null,
          ),
          _Tab(
            label: 'Login',
            isActive: activeTab == _ActiveTab.login,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _Tab({required this.label, required this.isActive, this.onTap});

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

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const _FieldLabel({required this.text, this.required = false});

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

class _ErrorBanner extends StatelessWidget {
  final List<String> errors;
  const _ErrorBanner({required this.errors});

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
          Row(
            children: const [
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
            (e) => Padding(
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
                      e,
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0xFFD8D8D8))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Or', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
        ),
        Expanded(child: Divider(color: Color(0xFFD8D8D8))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _SocialButton({required this.onPressed, required this.child});

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

// Simple Google "G" icon painted with canvas
class _GoogleIcon extends StatelessWidget {
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
    final r = size.width / 2;
    final c = Offset(r, r);

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start,
        sweep,
        true,
        Paint()..color = color,
      );
    }

    const pi = 3.14159265;
    arc(const Color(0xFF4285F4), -pi / 2, pi); // top-right blue
    arc(const Color(0xFF34A853), pi / 2, pi / 2); // bottom-right green
    arc(const Color(0xFFFBBC05), pi, pi / 2); // bottom-left yellow
    arc(const Color(0xFFEA4335), -pi / 2, -pi / 2); // top-left red

    // white center hole
    canvas.drawCircle(c, r * 0.65, Paint()..color = Colors.white);

    // white cutout for the G bar
    canvas.drawRect(
      Rect.fromLTWH(r, r - r * 0.18, r, r * 0.36),
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawRect(
      Rect.fromLTWH(r, r - r * 0.18, r, r * 0.36),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
