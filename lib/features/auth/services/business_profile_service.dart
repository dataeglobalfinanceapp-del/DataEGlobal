import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/features/auth/models/business_profile.dart';
import 'package:savetep/features/auth/models/business_profile_validator.dart';

abstract interface class BusinessProfileRepository {
  Future<BusinessProfile> load();

  Future<BusinessProfile> save(BusinessProfile profile);
}

class BusinessProfileService implements BusinessProfileRepository {
  static const String _profileKeyPrefix = 'business_profile_';
  static const String _legacyProfileKeyPrefix = 'account_profile_';

  final AccountIdentitySource _identitySource;

  const BusinessProfileService({
    AccountIdentitySource identitySource = const AmplifyAccountIdentitySource(),
  }) : _identitySource = identitySource;

  @override
  Future<BusinessProfile> load() async {
    final identity = await _identitySource.load();
    final profileKey = '$_profileKeyPrefix${identity.userId}';
    var shouldWrite = false;
    var profile = await _readProfile(profileKey);

    if (profile == null) {
      profile = await _readProfile(
        '$_legacyProfileKeyPrefix${identity.userId}',
      );
      shouldWrite = true;
    }

    profile ??= BusinessProfile(
      fullName: identity.fullName ?? '',
      email: identity.email ?? '',
    );

    final original = jsonEncode(profile.toJson());
    final identityFullName = identity.fullName?.trim() ?? '';
    final identityEmail = identity.email?.trim() ?? '';
    profile = profile.copyWith(
      fullName: identityFullName.isEmpty ? profile.fullName : identityFullName,
      email: profile.email.trim().isEmpty ? identityEmail : profile.email,
    );

    if (profile.setupCompleted &&
        !BusinessProfileValidator.validate(profile).isValid) {
      profile = profile.copyWith(setupCompleted: false);
    }

    if (shouldWrite || jsonEncode(profile.toJson()) != original) {
      await _writeProfile(profileKey, profile);
    }
    return profile;
  }

  @override
  Future<BusinessProfile> save(BusinessProfile profile) async {
    final completed = profile.normalized(setupCompleted: true);
    final validation = BusinessProfileValidator.validate(completed);
    if (!validation.isValid) {
      throw const FormatException('Business profile information is invalid.');
    }

    final identity = await _identitySource.load();
    final saved = completed.copyWith(
      fullName: completed.fullName.trim().isEmpty
          ? identity.fullName?.trim() ?? ''
          : completed.fullName,
    );
    await _writeProfile('$_profileKeyPrefix${identity.userId}', saved);
    return saved;
  }

  static Future<BusinessProfile?> _readProfile(String key) async {
    final encoded = await LocalStore.read(key);
    if (encoded == null || encoded.isEmpty) return null;
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, Object?>) return null;
    return BusinessProfile.fromJson(decoded);
  }

  static Future<void> _writeProfile(String key, BusinessProfile profile) {
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
