import 'dart:async';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/amplify_auth_configuration.dart';
import 'core/config/app_environment.dart';
import 'features/auth/screens/login_screen/forgot_password/confirm_reset_screen.dart';
import 'features/auth/screens/login_screen/forgot_password/forgot_password_screen.dart';
import 'features/auth/screens/login_screen/login/login_screen.dart';
import 'features/auth/screens/login_screen/onboarding/business_name_onboarding_screen.dart';
import 'features/auth/screens/login_screen/onboarding/business_category/business_category_screen.dart';
import 'features/auth/screens/login_screen/onboarding/splash_screen.dart';
import 'features/auth/screens/login_screen/shared/models/auth_flow_arguments.dart';
import 'features/auth/screens/login_screen/signup/confirm_signup_screen.dart';
import 'features/auth/screens/login_screen/signup/signup_screen.dart';
import 'features/auth/screens/home_screen/home_screen.dart';
import 'features/auth/screens/scan_screen/scan.dart';
import 'features/auth/screens/scan_screen/deposit_screen/scan_deposit_choice.dart';
import 'features/auth/screens/scan_screen/expense_screen/scan_expense_auto_screen.dart';
import 'features/auth/screens/scan_screen/mindee/mindee_config.dart';
import 'features/auth/screens/transaction_screen/transaction_screen.dart';
import 'features/auth/screens/liabilities_screen/liabilities_screen.dart';
import 'features/auth/screens/saving_screen/saving_screen.dart';
import 'features/auth/screens/payroll_screen/payroll_screen.dart';
import 'features/auth/screens/reminder_screen/reminder_screen.dart';
import 'features/auth/screens/profit_loss_screen/profit_loss_screen.dart';
import 'features/auth/screens/user_settings/user_settings_screens.dart';
import 'features/auth/widgets/bottom_nav_bar.dart';
import 'providers/api_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/test_clock_overlay.dart';

final GlobalKey<NavigatorState> _appNavigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final AppEnvironment environment = AppEnvironment.fromCompileTime();
    if (kDebugMode) MindeeConfig.validate();
    await _configureAmplify(environment);
    runApp(
      ProviderScope(
        overrides: [appEnvironmentProvider.overrideWithValue(environment)],
        child: const SaveTepApp(),
      ),
    );
  } on StateError catch (e) {
    runApp(
      ProviderScope(child: _StartupConfigurationErrorApp(message: e.message)),
    );
  } on AmplifyException catch (e) {
    runApp(
      ProviderScope(child: _AmplifyConfigurationErrorApp(message: e.message)),
    );
  }
}

class _StartupConfigurationErrorApp extends StatelessWidget {
  final String message;

  const _StartupConfigurationErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Startup configuration error: $message',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _configureAmplify(AppEnvironment environment) async {
  await Amplify.addPlugin(AmplifyAuthCognito());
  await Amplify.configure(buildAmplifyAuthConfiguration(environment));
  safePrint('Amplify configured for ${environment.authEnvironment.value}');
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

class SaveTepApp extends StatefulWidget {
  final String? initialRoute;

  const SaveTepApp({super.key, this.initialRoute});

  @override
  State<SaveTepApp> createState() => _SaveTepAppState();
}

class _SaveTepAppState extends State<SaveTepApp> {
  final ValueNotifier<AppBottomNavItem?> _currentBottomNavItem =
      ValueNotifier<AppBottomNavItem?>(null);

  @override
  void dispose() {
    _currentBottomNavItem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StartupFocusGate(
      child: MaterialApp(
        navigatorKey: _appNavigatorKey,
        navigatorObservers: [
          _BottomNavRouteObserver(currentItem: _currentBottomNavItem),
        ],
        initialRoute: widget.initialRoute,
        title: 'Save Tep',
        debugShowCheckedModeBanner: false,
        theme: buildSaveTepTheme(),
        builder: (context, child) {
          return FocusTraversalGroup(
            policy: WidgetOrderTraversalPolicy(),
            child: TestClockOverlay(
              navigatorKey: _appNavigatorKey,
              child: _AppBottomNavShell(
                navigatorKey: _appNavigatorKey,
                currentItemListenable: _currentBottomNavItem,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
        home: widget.initialRoute == null ? const SplashScreen() : null,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/confirm-signup': (context) {
            final arguments = ModalRoute.of(context)!.settings.arguments;
            if (arguments is ConfirmSignUpArguments) {
              return ConfirmSignUpScreen(
                email: arguments.email,
                fullName: arguments.fullName,
                codeDelivery: arguments.codeDelivery,
              );
            }
            return ConfirmSignUpScreen(email: arguments as String);
          },
          UserSettingsRoutes.businessSetup: (context) =>
              const BusinessManagementScreen(isSetupFlow: true),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/confirm-reset': (context) {
            final email = ModalRoute.of(context)!.settings.arguments as String;
            return ConfirmResetScreen(email: email);
          },
          '/business-name-onboarding': (context) {
            final arguments = ModalRoute.of(context)!.settings.arguments;
            final onboarding = arguments as BusinessNameOnboardingArguments;
            return BusinessNameOnboardingScreen(
              email: onboarding.email,
              fullName: onboarding.fullName,
            );
          },
          '/business-categories-onboarding': (context) {
            final arguments = ModalRoute.of(context)!.settings.arguments;
            final onboarding = arguments as BusinessCategoryOnboardingArguments;
            return BusinessCategoryScreen(
              businessProfile: onboarding.businessProfile,
              initialSelectedCategoryIds: onboarding.initialSelectedCategoryIds,
            );
          },
          '/home': (context) => const HomeScreen(),
          '/scan': (context) => const ScanScreen(),
          '/scan-deposit': (context) => const ScanDepositScreen(),
          '/scan-expense': (context) => const ScanExpenseAutoScreen(),
          '/transactions': (context) {
            final arguments = ModalRoute.of(context)?.settings.arguments;
            if (arguments is TransactionScreenArguments) {
              return TransactionScreen(
                initialExpenseDateRange: arguments.initialExpenseDateRange,
                initialExpenseCategory: arguments.initialExpenseCategory,
              );
            }
            return const TransactionScreen();
          },
          '/liabilities': (context) => const LiabilitiesScreen(),
          '/saving': (context) => const SavingScreen(),
          '/payroll': (context) => const PayrollScreen(),
          '/reminders': (context) => const ReminderScreen(),
          '/profit-loss': (context) => const ProfitLossScreen(),
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

class _AppBottomNavShell extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final ValueNotifier<AppBottomNavItem?> currentItemListenable;
  final Widget child;

  const _AppBottomNavShell({
    required this.navigatorKey,
    required this.currentItemListenable,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppBottomNavItem?>(
      valueListenable: currentItemListenable,
      child: child,
      builder: (context, currentItem, child) {
        final routeContent = child ?? const SizedBox.shrink();
        if (currentItem == null) return routeContent;

        return Scaffold(
          body: routeContent,
          bottomNavigationBar: AppBottomNavigationBar(
            currentItem: currentItem,
            onItemSelected: (item) {
              navigatorKey.currentState?.pushReplacementNamed(item.routeName);
            },
          ),
        );
      },
    );
  }
}

class _BottomNavRouteObserver extends NavigatorObserver {
  final ValueNotifier<AppBottomNavItem?> currentItem;

  _BottomNavRouteObserver({required this.currentItem});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sync(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sync(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sync(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _sync(newRoute);
  }

  void _sync(Route<dynamic>? route) {
    final nextItem = bottomNavItemForRouteName(
      route?.settings.name,
      fallback: currentItem.value,
    );
    if (currentItem.value == nextItem) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentItem.value != nextItem) {
        currentItem.value = nextItem;
      }
    });
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
