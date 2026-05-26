import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'amplify_outputs.dart';
import 'features/auth/screens/login_screen/confirm_reset_screen.dart';
import 'features/auth/screens/login_screen/login_screen.dart';
import 'features/auth/screens/login_screen/signup_screen.dart';
import 'features/auth/screens/login_screen/confirm_signup_screen.dart';
import 'features/auth/screens/login_screen/forgot_password_screen.dart';
import 'features/auth/screens/home_screen/home_screen.dart';
import 'features/auth/screens/login_screen/splash_screen.dart';
import 'features/auth/screens/scan_screen/scan_deposit_screen.dart';
import 'features/auth/screens/scan_screen/scan_expense_screen.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await _configureAmplify();
    runApp(const BizTrackApp());
  } on AmplifyException catch (e) {
    runApp(_AmplifyConfigurationErrorApp(message: e.message));
  }
}

Future<void> _configureAmplify() async {
  await Amplify.addPlugin(AmplifyAuthCognito());
  await Amplify.configure(amplifyConfig);
  safePrint('Amplify configured ✓');
}

class _AmplifyConfigurationErrorApp extends StatelessWidget {
  final String message;

  const _AmplifyConfigurationErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error configuring Amplify: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class BizTrackApp extends StatelessWidget {
  const BizTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fin App',
      debugShowCheckedModeBanner: false, // ← hides debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // ← matches chart blue
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins', // ← add Poppins to pubspec.yaml
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/confirm-signup': (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return ConfirmSignUpScreen(email: email);
        },
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/confirm-reset': (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return ConfirmResetScreen(email: email);
        },
        '/home': (context) => const HomeScreen(),
        '/scan-deposit': (context) => const ScanDepositScreen(),
        '/scan-expense': (context) => const ScanExpenseScreen(),
      },
    );
  }
}
