class AccountProfile {
  static const String fallbackDisplayName = 'SaveTep';

  final String? fullName;
  final String? businessName;
  final bool businessNameOnboardingCompleted;

  const AccountProfile({
    this.fullName,
    this.businessName,
    required this.businessNameOnboardingCompleted,
  });

  String get displayName =>
      _normalized(businessName) ?? _normalized(fullName) ?? fallbackDisplayName;

  AccountProfile copyWith({
    String? fullName,
    bool clearFullName = false,
    String? businessName,
    bool clearBusinessName = false,
    bool? businessNameOnboardingCompleted,
  }) {
    return AccountProfile(
      fullName: clearFullName ? null : _normalized(fullName) ?? this.fullName,
      businessName: clearBusinessName
          ? null
          : normalizeBusinessName(businessName) ?? this.businessName,
      businessNameOnboardingCompleted:
          businessNameOnboardingCompleted ??
          this.businessNameOnboardingCompleted,
    );
  }

  AccountProfile withBusinessName(
    String? value, {
    bool onboardingCompleted = true,
  }) {
    final normalized = normalizeBusinessName(value);
    return AccountProfile(
      fullName: fullName,
      businessName: normalized,
      businessNameOnboardingCompleted: onboardingCompleted,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'fullName': _normalized(fullName),
    'businessName': normalizeBusinessName(businessName),
    'businessNameOnboardingCompleted': businessNameOnboardingCompleted,
  };

  factory AccountProfile.fromJson(Map<String, Object?> json) {
    return AccountProfile(
      fullName: _normalized(json['fullName'] as String?),
      businessName: normalizeBusinessName(json['businessName'] as String?),
      businessNameOnboardingCompleted:
          json['businessNameOnboardingCompleted'] as bool? ?? true,
    );
  }

  static String? normalizeBusinessName(String? value) {
    final normalized = _normalized(value);
    if (normalized == null ||
        normalized.toLowerCase() == fallbackDisplayName.toLowerCase()) {
      return null;
    }
    return normalized;
  }

  static String? _normalized(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
