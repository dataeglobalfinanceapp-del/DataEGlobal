import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/features/auth/models/account_profile.dart';

abstract interface class AccountProfileRepository {
  Future<AccountProfile> load();

  Future<void> save(AccountProfile profile);
}

class AccountProfileService implements AccountProfileRepository {
  static const String _accountKeyPrefix = 'account_profile_';
  static const String _pendingKeyPrefix = 'pending_account_profile_';

  final AccountIdentitySource _identitySource;

  const AccountProfileService({
    AccountIdentitySource identitySource = const AmplifyAccountIdentitySource(),
  }) : _identitySource = identitySource;

  static Future<void> stageNewAccount({
    required String email,
    required String fullName,
  }) {
    return _writeProfile(
      _pendingKey(email),
      AccountProfile(
        fullName: fullName.trim(),
        businessNameOnboardingCompleted: false,
      ),
    );
  }

  static Future<void> completePendingOnboarding({
    required String email,
    required String fullName,
    String? businessName,
  }) {
    return _writeProfile(
      _pendingKey(email),
      AccountProfile(
        fullName: fullName.trim(),
        businessName: AccountProfile.normalizeBusinessName(businessName),
        businessNameOnboardingCompleted: true,
      ),
    );
  }

  @override
  Future<AccountProfile> load() async {
    final identity = await _identitySource.load();
    final accountKey = '$_accountKeyPrefix${identity.userId}';
    final saved = await _readProfile(accountKey);
    if (saved != null) {
      final merged = saved.copyWith(fullName: identity.fullName);
      if (merged.fullName != saved.fullName) {
        await _writeProfile(accountKey, merged);
      }
      return merged;
    }

    final pending = identity.email == null
        ? null
        : await _readProfile(_pendingKey(identity.email!));
    final profile = pending == null
        ? AccountProfile(
            fullName: identity.fullName,
            businessNameOnboardingCompleted: true,
          )
        : pending.copyWith(fullName: identity.fullName);
    await _writeProfile(accountKey, profile);
    return profile;
  }

  @override
  Future<void> save(AccountProfile profile) async {
    final identity = await _identitySource.load();
    await _writeProfile('$_accountKeyPrefix${identity.userId}', profile);
  }

  static String _pendingKey(String email) {
    final encodedEmail = base64Url.encode(
      utf8.encode(email.trim().toLowerCase()),
    );
    return '$_pendingKeyPrefix$encodedEmail';
  }

  static Future<AccountProfile?> _readProfile(String key) async {
    final encoded = await LocalStore.read(key);
    if (encoded == null || encoded.isEmpty) return null;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, Object?>) return null;
    return AccountProfile.fromJson(decoded);
  }

  static Future<void> _writeProfile(String key, AccountProfile profile) {
    return LocalStore.write(key, jsonEncode(profile.toJson()));
  }
}

class AccountIdentity {
  final String userId;
  final String? email;
  final String? fullName;

  const AccountIdentity({required this.userId, this.email, this.fullName});
}

abstract interface class AccountIdentitySource {
  Future<AccountIdentity> load();
}

class AmplifyAccountIdentitySource implements AccountIdentitySource {
  const AmplifyAccountIdentitySource();

  @override
  Future<AccountIdentity> load() async {
    final user = await Amplify.Auth.getCurrentUser();
    final attributes = await Amplify.Auth.fetchUserAttributes();
    String? valueFor(AuthUserAttributeKey key) {
      for (final attribute in attributes) {
        if (attribute.userAttributeKey == key) return attribute.value;
      }
      return null;
    }

    return AccountIdentity(
      userId: user.userId,
      email: valueFor(AuthUserAttributeKey.email) ?? user.username,
      fullName: valueFor(AuthUserAttributeKey.name),
    );
  }
}
