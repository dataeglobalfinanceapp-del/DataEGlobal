import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'confirm_signup_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  String _countryCode = '+84';

  // Validation state
  List<String> _errors = [];
  bool _nameInvalid = false;
  bool _emailInvalid = false;
  bool _phoneInvalid = false;
  bool _passwordInvalid = false;
  bool _confirmInvalid = false;

  static const List<String> _countryCodes = [
    '+1',
    '+7',
    '+20',
    '+27',
    '+30',
    '+31',
    '+32',
    '+33',
    '+34',
    '+36',
    '+39',
    '+40',
    '+41',
    '+44',
    '+45',
    '+46',
    '+47',
    '+48',
    '+49',
    '+51',
    '+52',
    '+54',
    '+55',
    '+56',
    '+57',
    '+60',
    '+61',
    '+62',
    '+63',
    '+64',
    '+65',
    '+66',
    '+81',
    '+82',
    '+84',
    '+86',
    '+90',
    '+91',
    '+92',
    '+94',
    '+95',
    '+98',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool _validate() {
    final errors = <String>[];

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    final nameOk = name.isNotEmpty;
    final emailOk = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

    final phoneOk = RegExp(r'^\d{9,10}$').hasMatch(phone);

    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*]').hasMatch(password);

    final passwordOk =
        hasMinLength && hasUppercase && hasLowercase && hasNumber && hasSpecial;

    final confirmOk = confirm == password;

    if (!nameOk) {
      errors.add('Username is required');
    }

    if (!emailOk) {
      errors.add('A valid email is required');
    }

    if (!phoneOk) {
      errors.add('A valid phone number is required');
    }

    if (!hasMinLength) {
      errors.add('Password must be at least 8 characters');
    }

    if (!hasUppercase) {
      errors.add('Password must contain at least one uppercase letter');
    }

    if (!hasLowercase) {
      errors.add('Password must contain at least one lowercase letter');
    }

    if (!hasNumber) {
      errors.add('Password must contain at least one number');
    }

    if (!hasSpecial) {
      errors.add(
        'Password must contain at least one special character (!@#\$%^&*)',
      );
    }

    if (password.isNotEmpty && !confirmOk) {
      errors.add('Passwords do not match');
    }

    if (!_agreedToTerms) {
      errors.add('Please accept the terms and conditions');
    }

    setState(() {
      _errors = errors;
      _nameInvalid = !nameOk;
      _emailInvalid = !emailOk;
      _phoneInvalid = !phoneOk;
      _passwordInvalid = !passwordOk;
      _confirmInvalid = password.isNotEmpty && !confirmOk;
    });

    return errors.isEmpty;
  }

  // ── Sign-up ───────────────────────────────────────────────────────────────

  Future<void> _signUp() async {
    if (!_validate()) return;

    setState(() => _loading = true);
    try {
      final signUp = await AuthService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      if (signUp.needsConfirmation) {
        Navigator.pushNamed(
          context,
          '/confirm-signup',
          arguments: ConfirmSignUpArguments(
            email: _emailController.text.trim(),
            codeDelivery: signUp.codeDelivery,
          ),
        );
      }
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
                'Savings Teps',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2340),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Create your executive account',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 24),

              // ── Tab bar ───────────────────────────────────────────────────
              AuthTabBar(
                activeTab: AuthTab.signup,
                onLoginTap: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
              ),
              const SizedBox(height: 20),

              // ── Error banner ──────────────────────────────────────────────
              if (_errors.isNotEmpty) ...[
                AuthErrorBanner(errors: _errors),
                const SizedBox(height: 16),
              ],

              // ── Full name ─────────────────────────────────────────────────
              AuthFieldLabel(text: 'FULL NAME', required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: authFieldDecoration(
                  hint: 'e.g: Sunny',
                  invalid: _nameInvalid,
                ),
              ),
              const SizedBox(height: 16),

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

              // ── Phone ─────────────────────────────────────────────────────
              AuthFieldLabel(text: 'PHONE', required: true),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Country code picker
                  GestureDetector(
                    onTap: _pickCountryCode,
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _phoneInvalid
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _countryCode,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF222222),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: Color(0xFF888888),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: authFieldDecoration(
                        hint: '23456788889',
                        invalid: _phoneInvalid,
                      ),
                    ),
                  ),
                ],
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
              const SizedBox(height: 16),

              // ── Confirm password ──────────────────────────────────────────
              AuthFieldLabel(text: 'CONFIRM PASSWORD', required: true),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: authFieldDecoration(
                  hint: '••••••••••••',
                  invalid: _confirmInvalid,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Terms checkbox ────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (v) =>
                        setState(() => _agreedToTerms = v ?? false),
                    activeColor: const Color(0xFF1A2340),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'I have read and agree to the terms and conditions',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Sign Up button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signUp,
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
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Login link ────────────────────────────────────────────────
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                  ),
                  children: [
                    const TextSpan(text: 'Already have an account. '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text(
                          'Log in',
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

  // ── Country code bottom sheet ─────────────────────────────────────────────

  void _pickCountryCode() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select country code',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ..._countryCodes.map(
            (code) => ListTile(
              title: Text(code),
              trailing: code == _countryCode
                  ? const Icon(Icons.check, color: Color(0xFF1A2340))
                  : null,
              onTap: () {
                setState(() => _countryCode = code);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
