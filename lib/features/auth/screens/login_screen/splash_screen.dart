import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:savetep/providers/business_profile_provider.dart';

import '../../services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _errorMessage;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAuth();
      }
    });
  }

  Future<void> _checkAuth() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _errorMessage = null;
    });

    bool signedIn;
    try {
      signedIn = await AuthService.isSignedIn();
    } catch (_) {
      signedIn = false;
    }

    if (!mounted) return;
    if (!signedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      ref.invalidate(businessProfileProvider);
      final profile = await ref.read(businessProfileProvider.future);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        profile.setupCompleted ? '/home' : '/business-setup',
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _errorMessage = 'Could not load business setup: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    return Scaffold(
      body: Center(
        child: errorMessage == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
  }
}
