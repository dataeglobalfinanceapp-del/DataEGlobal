import 'dart:convert';

import 'local_store.dart';

class ReminderService {
  static const _storageKey = 'biztrack_reminders_v1';
  static final List<ReminderRecord> _reminders = [];
  static bool _loaded = false;

  static Future<List<ReminderRecord>> loadReminders() async {
    await _ensureLoaded();
    final records = List<ReminderRecord>.from(_reminders);
    records.sort((a, b) => a.date.compareTo(b.date));
    return List.unmodifiable(records);
  }

  static Future<void> saveReminders(List<ReminderDraft> drafts) async {
    await _ensureLoaded();
    for (final draft in drafts) {
      if (draft.amount <= 0) continue;
      _reminders.add(
        ReminderRecord(
          id: _newId('reminder'),
          date: draft.date,
          category: draft.category,
          amount: draft.amount,
          reminderCount: draft.reminderCount,
          payee: draft.payee.isEmpty ? draft.category : draft.payee,
          alertEnabled: true,
          createdAt: DateTime.now(),
        ),
      );
    }
    await _persist();
  }

  static Future<void> updateAlert(String id, bool enabled) async {
    await _ensureLoaded();
    final index = _reminders.indexWhere((record) => record.id == id);
    if (index == -1) return;
    _reminders[index] = _reminders[index].copyWith(alertEnabled: enabled);
    await _persist();
  }

  static Future<void> postpone(String id, {int days = 1}) async {
    await _ensureLoaded();
    final index = _reminders.indexWhere((record) => record.id == id);
    if (index == -1) return;
    final record = _reminders[index];
    _reminders[index] = record.copyWith(
      date: record.date.add(Duration(days: days)),
    );
    await _persist();
  }

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final raw = await LocalStore.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _loaded = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _reminders
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map(
              (entry) => ReminderRecord.fromJson(entry),
            ),
          );
      }
    } catch (_) {
      _reminders.clear();
    }

    _loaded = true;
  }

  static Future<void> _persist() async {
    final payload = jsonEncode(
      _reminders.map((record) => record.toJson()).toList(),
    );
    await LocalStore.write(_storageKey, payload);
  }

  static String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}

class ReminderDraft {
  final DateTime date;
  final String category;
  final double amount;
  final String reminderCount;
  final String payee;

  const ReminderDraft({
    required this.date,
    required this.category,
    required this.amount,
    required this.reminderCount,
    required this.payee,
  });
}

class ReminderRecord {
  final String id;
  final DateTime date;
  final String category;
  final double amount;
  final String reminderCount;
  final String payee;
  final bool alertEnabled;
  final DateTime createdAt;

  const ReminderRecord({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    required this.reminderCount,
    required this.payee,
    required this.alertEnabled,
    required this.createdAt,
  });

  factory ReminderRecord.fromJson(Map<dynamic, dynamic> json) {
    return ReminderRecord(
      id: _asString(json['id'], fallback: _fallbackId('reminder')),
      date: _asDate(json['date']),
      category: _asString(json['category'], fallback: 'Reminder'),
      amount: _asDouble(json['amount']),
      reminderCount: _asString(json['reminderCount'], fallback: 'Just one'),
      payee: _asString(json['payee'], fallback: 'Reminder'),
      alertEnabled: json['alertEnabled'] != false,
      createdAt: _asDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'category': category,
    'amount': amount,
    'reminderCount': reminderCount,
    'payee': payee,
    'alertEnabled': alertEnabled,
    'createdAt': createdAt.toIso8601String(),
  };

  ReminderRecord copyWith({
    DateTime? date,
    String? category,
    double? amount,
    String? reminderCount,
    String? payee,
    bool? alertEnabled,
  }) {
    return ReminderRecord(
      id: id,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      reminderCount: reminderCount ?? this.reminderCount,
      payee: payee ?? this.payee,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      createdAt: createdAt,
    );
  }
}

String _fallbackId(String prefix) =>
    '$prefix-imported-${DateTime.now().microsecondsSinceEpoch}';

String _asString(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime _asDate(Object? value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
