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
import 'features/auth/screens/scan_screen/scan.dart';
import 'features/auth/screens/scan_screen/deposit_screen/scan_deposit_choice.dart';
import 'features/auth/screens/scan_screen/expense_screen/scan_expense_choice.dart';
import 'features/auth/screens/transaction_screen/transaction_screen.dart';
import 'features/auth/screens/liabilities_screen/liabilities_screen.dart';
import 'features/auth/screens/reserves_screen/reserves_screen.dart';
import 'features/auth/screens/reminder_screen/reminder_screen.dart';
import 'features/auth/screens/tax_screen/tax_screen.dart';
import 'features/auth/screens/user_setting/user_setting_screens.dart';
import 'widgets/test_clock_overlay.dart';

final GlobalKey<NavigatorState> _appNavigatorKey = GlobalKey<NavigatorState>();

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
    return _StartupFocusGate(
      child: MaterialApp(
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
      ),
    );
  }
}

class BizTrackApp extends StatelessWidget {
  const BizTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartupFocusGate(
      child: MaterialApp(
        navigatorKey: _appNavigatorKey,
        title: 'Save Tep',
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
        builder: (context, child) {
          return FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: TestClockOverlay(
              navigatorKey: _appNavigatorKey,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/confirm-signup': (context) {
            final arguments = ModalRoute.of(context)!.settings.arguments;
            if (arguments is ConfirmSignUpArguments) {
              return ConfirmSignUpScreen(
                email: arguments.email,
                codeDelivery: arguments.codeDelivery,
              );
            }
            return ConfirmSignUpScreen(email: arguments as String);
          },
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/confirm-reset': (context) {
            final email = ModalRoute.of(context)!.settings.arguments as String;
            return ConfirmResetScreen(email: email);
          },
          '/home': (context) => const HomeScreen(),
          '/scan': (context) => const ScanScreen(),
          '/scan-deposit': (context) => const ScanDepositScreen(),
          '/scan-expense': (context) => const ScanExpenseScreen(),
          '/transactions': (context) => const TransactionScreen(),
          '/liabilities': (context) => const LiabilitiesScreen(),
          '/reserves': (context) => const ReservesScreen(),
          '/reminders': (context) => const ReminderScreen(),
          '/tax': (context) => const TaxScreen(),
          UserSettingsRoutes.settings: (context) => const UserSettingsScreen(),
          UserSettingsRoutes.businessManagement: (context) =>
              const BusinessManagementScreen(),
          UserSettingsRoutes.enterpriseCodeId: (context) =>
              const EnterpriseCodeIdScreen(),
          UserSettingsRoutes.changePassword: (context) =>
              const ChangePasswordScreen(),
          UserSettingsRoutes.institutionSupport: (context) =>
              const InstitutionSupportScreen(),
          UserSettingsRoutes.managePartner: (context) =>
              const ManagePartnerScreen(),
          UserSettingsRoutes.deactivateAccess: (context) =>
              const DeactivateAccessScreen(),
        },
      ),
    );
  }
}

class _StartupFocusGate extends StatefulWidget {
  final Widget child;

  const _StartupFocusGate({required this.child});

  @override
  State<_StartupFocusGate> createState() => _StartupFocusGateState();
}

class _StartupFocusGateState extends State<_StartupFocusGate> {
  bool _focusReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _focusReady = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      key: const Key('startup-focus-gate'),
      canRequestFocus: _focusReady,
      descendantsAreFocusable: _focusReady,
      descendantsAreTraversable: _focusReady,
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: widget.child,
      ),
    );
  }
}
