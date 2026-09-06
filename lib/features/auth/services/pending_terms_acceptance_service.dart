import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:savetep/data/local/local_store.dart';

abstract interface class PendingTermsAcceptanceRepository {
  Future<String?> loadForCurrentUser();

  Future<void> markSubmittedForCurrentUser();
}

class PendingTermsAcceptanceService
    implements PendingTermsAcceptanceRepository {
  static const String _keyPrefix = 'pending_terms_acceptance_';

  final TermsAcceptanceIdentitySource _identitySource;

  const PendingTermsAcceptanceService({
    TermsAcceptanceIdentitySource identitySource =
        const AmplifyTermsAcceptanceIdentitySource(),
  }) : _identitySource = identitySource;

  static Future<void> stage({
    required String email,
    required String termsVersion,
  }) {
    final String normalizedVersion = termsVersion.trim();
    if (normalizedVersion.isEmpty || normalizedVersion.length > 64) {
      throw ArgumentError.value(
        termsVersion,
        'termsVersion',
        'must contain 1 to 64 characters',
      );
    }
    return LocalStore.write(_key(email), normalizedVersion);
  }

  @override
  Future<String?> loadForCurrentUser() async {
    final String email = await _identitySource.loadEmail();
    final String? value = await LocalStore.read(_key(email));
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Future<void> markSubmittedForCurrentUser() async {
    final String email = await _identitySource.loadEmail();
    await LocalStore.write(_key(email), '');
  }

  static String _key(String email) {
    final String normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw ArgumentError.value(email, 'email', 'must not be empty');
    }
    final String encoded = base64Url.encode(utf8.encode(normalizedEmail));
    return '$_keyPrefix$encoded';
  }
}

abstract interface class TermsAcceptanceIdentitySource {
  Future<String> loadEmail();
}

class AmplifyTermsAcceptanceIdentitySource
    implements TermsAcceptanceIdentitySource {
  const AmplifyTermsAcceptanceIdentitySource();

  @override
  Future<String> loadEmail() async {
    final AuthUser user = await Amplify.Auth.getCurrentUser();
    final List<AuthUserAttribute> attributes =
        await Amplify.Auth.fetchUserAttributes();
    for (final AuthUserAttribute attribute in attributes) {
      if (attribute.userAttributeKey == AuthUserAttributeKey.email &&
          attribute.value.trim().isNotEmpty) {
        return attribute.value;
      }
    }
    return user.username;
  }
}
