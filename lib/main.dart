import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'amplify_outputs.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/confirm_signup_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/confirm_reset_screen.dart';
import 'features/auth/screens/home_screen.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await _configureAmplify();
    runApp(const BizTrackApp());
  } on AmplifyException catch (e) {
    runApp(Text('Error configuring Amplify: ${e.message}'));
  }
}

Future<void> _configureAmplify() async {
  await Amplify.addPlugin(AmplifyAuthCognito());
  await Amplify.configure(amplifyConfig);
  safePrint('Amplify configured ✓');
}

class BizTrackApp extends StatelessWidget {
  const BizTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BizTrack',
      debugShowCheckedModeBanner: false,        // ← hides debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),   // ← matches chart blue
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',                  // ← add Poppins to pubspec.yaml
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login':           (context) => const LoginScreen(),
        '/signup':          (context) => const SignUpScreen(),
        '/confirm-signup':  (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return ConfirmSignUpScreen(email: email);
        },
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/confirm-reset':   (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return ConfirmResetScreen(email: email);
        },
        '/home':            (context) => const HomeScreen(),
      },
    );
  }
}