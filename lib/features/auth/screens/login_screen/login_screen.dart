import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  // Validation errors shown in the red banner
  List<String> _errors = [];

  // Whether a field has been flagged invalid (for red border)
  bool _emailInvalid = false;
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
      _errors = errors;
      _emailInvalid = !emailOk;
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
                'Fin App',
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
              AuthTabBar(
                activeTab: AuthTab.login,
                onSignUpTap: () =>
                    Navigator.pushReplacementNamed(context, '/signup'),
              ),
              const SizedBox(height: 20),

              // ── Error banner ──────────────────────────────────────────────
              if (_errors.isNotEmpty) ...[
                AuthErrorBanner(errors: _errors),
                const SizedBox(height: 16),
              ],

              // ── Email ─────────────────────────────────────────────────────
              AuthFieldLabel(text: 'EMAIL', required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: authFieldDecoration(
                  hint: 'e.g: sunny@gmail.com',
                  invalid: _emailInvalid,
                ),
              ),
              const SizedBox(height: 16),

              // ── Password ──────────────────────────────────────────────────
              AuthFieldLabel(text: 'PASSWORD', required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: authFieldDecoration(
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
              AuthSocialButton(
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
              AuthSocialButton(
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                  ),
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
// Login-only sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0xFFD8D8D8))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or',
            style: TextStyle(color: Color(0xFF888888), fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFD8D8D8))),
      ],
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
