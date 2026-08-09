class BusinessProfile {
  static const String fallbackDisplayName = 'SaveTep';

  final String fullName;
  final String businessName;
  final String dba;
  final String address;
  final String ein;
  final String email;
  final String phone;
  final bool setupCompleted;

  const BusinessProfile({
    this.fullName = '',
    this.businessName = '',
    this.dba = '',
    this.address = '',
    this.ein = '',
    this.email = '',
    this.phone = '',
    this.setupCompleted = false,
  });

  String get displayName {
    final normalizedBusinessName = businessName.trim();
    if (normalizedBusinessName.isNotEmpty) return normalizedBusinessName;

    final normalizedFullName = fullName.trim();
    return normalizedFullName.isNotEmpty
        ? normalizedFullName
        : fallbackDisplayName;
  }

  BusinessProfile copyWith({
    String? fullName,
    String? businessName,
    String? dba,
    String? address,
    String? ein,
    String? email,
    String? phone,
    bool? setupCompleted,
  }) {
    return BusinessProfile(
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      dba: dba ?? this.dba,
      address: address ?? this.address,
      ein: ein ?? this.ein,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      setupCompleted: setupCompleted ?? this.setupCompleted,
    );
  }

  BusinessProfile normalized({bool? setupCompleted}) {
    return BusinessProfile(
      fullName: fullName.trim(),
      businessName: businessName.trim(),
      dba: dba.trim(),
      address: address.trim(),
      ein: ein.trim(),
      email: email.trim(),
      phone: phone.trim(),
      setupCompleted: setupCompleted ?? this.setupCompleted,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'fullName': fullName.trim(),
    'businessName': businessName.trim(),
    'dba': dba.trim(),
    'address': address.trim(),
    'ein': ein.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'businessSetupCompleted': setupCompleted,
  };

  factory BusinessProfile.fromJson(Map<String, Object?> json) {
    String value(String key) {
      final rawValue = json[key];
      return rawValue is String ? rawValue.trim() : '';
    }

    return BusinessProfile(
      fullName: value('fullName'),
      businessName: value('businessName'),
      dba: value('dba'),
      address: value('address'),
      ein: value('ein'),
      email: value('email'),
      phone: value('phone'),
      setupCompleted:
          json['businessSetupCompleted'] as bool? ??
          json['setupCompleted'] as bool? ??
          false,
    );
  }
}
