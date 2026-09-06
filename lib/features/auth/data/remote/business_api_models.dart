enum BusinessType {
  nailSalon('NAIL_SALON'),
  retail('RETAIL'),
  restaurant('RESTAURANT'),
  other('OTHER');

  final String wireValue;

  const BusinessType(this.wireValue);

  static BusinessType? tryParse(String value) {
    for (final type in values) {
      if (type.wireValue == value) return type;
    }
    return null;
  }
}

class BusinessResponseDto {
  final String id;
  final String name;

  /// Raw value is retained so a newer backend enum is not silently rewritten.
  final String rawType;
  final String currency;
  final String timezone;
  final String? state;
  final String? referralCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessResponseDto({
    required this.id,
    required this.name,
    required this.rawType,
    required this.currency,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    this.state,
    this.referralCode,
  });

  BusinessType? get type => BusinessType.tryParse(rawType);

  bool get hasKnownType => type != null;

  factory BusinessResponseDto.fromJson(Map<String, Object?> json) {
    return BusinessResponseDto(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      rawType: _requiredString(json, 'type'),
      currency: _requiredString(json, 'currency'),
      timezone: _requiredString(json, 'timezone'),
      state: _optionalString(json, 'state'),
      referralCode: _optionalString(json, 'referralCode'),
      createdAt: _requiredDateTime(json, 'createdAt'),
      updatedAt: _requiredDateTime(json, 'updatedAt'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'type': rawType,
    'currency': currency,
    'timezone': timezone,
    'state': state,
    'referralCode': referralCode,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class CreateBusinessDto {
  final String name;
  final BusinessType type;
  final String? currency;
  final String? timezone;
  final String? state;
  final String? referralCodeUsed;

  const CreateBusinessDto({
    required this.name,
    required this.type,
    this.currency,
    this.timezone,
    this.state,
    this.referralCodeUsed,
  });

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'type': type.wireValue,
    if (currency != null) 'currency': currency,
    if (timezone != null) 'timezone': timezone,
    if (state != null) 'state': state,
    if (referralCodeUsed != null) 'referralCodeUsed': referralCodeUsed,
  };
}

class UpdateBusinessDto {
  final String? name;
  final BusinessType? type;
  final String? currency;
  final String? timezone;
  final String? state;

  const UpdateBusinessDto({
    this.name,
    this.type,
    this.currency,
    this.timezone,
    this.state,
  });

  Map<String, Object?> toJson() => <String, Object?>{
    if (name != null) 'name': name,
    if (type != null) 'type': type!.wireValue,
    if (currency != null) 'currency': currency,
    if (timezone != null) 'timezone': timezone,
    if (state != null) 'state': state,
  };
}

class DeactivationDisclosureResponseDto {
  final num retentionDays;
  final String canReactivateUntil;
  final String warningMessage;

  const DeactivationDisclosureResponseDto({
    required this.retentionDays,
    required this.canReactivateUntil,
    required this.warningMessage,
  });

  factory DeactivationDisclosureResponseDto.fromJson(
    Map<String, Object?> json,
  ) {
    return DeactivationDisclosureResponseDto(
      retentionDays: _requiredNumber(json, 'retentionDays'),
      canReactivateUntil: _requiredString(json, 'canReactivateUntil'),
      warningMessage: _requiredString(json, 'warningMessage'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'retentionDays': retentionDays,
    'canReactivateUntil': canReactivateUntil,
    'warningMessage': warningMessage,
  };
}

class DeactivateBusinessDto {
  final bool confirm;

  const DeactivateBusinessDto({required this.confirm});

  Map<String, Object?> toJson() => <String, Object?>{'confirm': confirm};
}

class ActiveBusinessResponseDto {
  final BusinessResponseDto? business;

  const ActiveBusinessResponseDto({this.business});

  factory ActiveBusinessResponseDto.fromJson(Map<String, Object?> json) {
    final businessJson = json['business'];
    if (businessJson == null) return const ActiveBusinessResponseDto();
    return ActiveBusinessResponseDto(
      business: BusinessResponseDto.fromJson(_jsonObject(businessJson)),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'business': business?.toJson(),
  };
}

class SetActiveBusinessDto {
  final String businessId;

  const SetActiveBusinessDto({required this.businessId});

  Map<String, Object?> toJson() => <String, Object?>{'businessId': businessId};
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return Map<String, Object?>.from(value);
  throw const FormatException('Expected a JSON object.');
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Expected "$key" to be a string.');
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Expected "$key" to be a string or null.');
}

DateTime _requiredDateTime(Map<String, Object?> json, String key) {
  final value = _requiredString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed != null) return parsed;
  throw FormatException('Expected "$key" to be an ISO 8601 date-time.');
}

num _requiredNumber(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num) return value;
  throw FormatException('Expected "$key" to be a number.');
}
