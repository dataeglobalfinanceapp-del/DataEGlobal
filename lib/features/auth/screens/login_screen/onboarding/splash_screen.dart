import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/features/auth/screens/login_screen/shared/models/auth_flow_destination.dart';
import 'package:savetep/features/auth/screens/login_screen/shared/repositories/auth_repository.dart';
import 'package:savetep/providers/business_profile_provider.dart';

import 'controllers/splash_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const AuthRepository _authRepository = ServiceAuthRepository();

  late final SplashController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SplashController(
      checkAuthSession: _authRepository.isSignedIn,
      loadBusinessSetupCompleted: () async {
        ref.invalidate(businessProfileProvider);
        final profile = await ref.read(businessProfileProvider.future);
        return profile.setupCompleted;
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAuth();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final AuthFlowDestination? destination = await _controller.check();
    if (!mounted || destination == null) return;
    Navigator.pushReplacementNamed(context, _routeFor(destination));
  }

  String _routeFor(AuthFlowDestination destination) {
    return switch (destination) {
      AuthFlowDestination.login => '/login',
      AuthFlowDestination.home => '/home',
      AuthFlowDestination.businessSetup => '/business-setup',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final String? errorMessage = _controller.state.errorMessage;
        return Scaffold(
          body: Center(
            child: errorMessage == null
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(errorMessage, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _checkAuth,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
