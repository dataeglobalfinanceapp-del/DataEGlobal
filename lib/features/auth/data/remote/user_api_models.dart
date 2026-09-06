class MeResponseDto {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String locale;
  final DateTime createdAt;

  const MeResponseDto({
    required this.id,
    required this.email,
    required this.locale,
    required this.createdAt,
    this.name,
    this.phone,
  });

  factory MeResponseDto.fromJson(Map<String, Object?> json) {
    return MeResponseDto(
      id: _requiredString(json, 'id'),
      email: _requiredString(json, 'email'),
      name: _optionalString(json, 'name'),
      phone: _optionalString(json, 'phone'),
      locale: _requiredString(json, 'locale'),
      createdAt: _requiredDateTime(json, 'createdAt'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'email': email,
    if (name != null) 'name': name,
    if (phone != null) 'phone': phone,
    'locale': locale,
    'createdAt': createdAt.toIso8601String(),
  };
}

class UpdateMeDto {
  final String? name;
  final String? phone;
  final String? locale;

  const UpdateMeDto({this.name, this.phone, this.locale});

  Map<String, Object?> toJson() => <String, Object?>{
    if (name != null) 'name': name,
    if (phone != null) 'phone': phone,
    if (locale != null) 'locale': locale,
  };
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
