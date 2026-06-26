import 'dart:convert';

import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/data/repositories/reminder_repository.dart';

class LocalReminderRepository implements ReminderRepository {
  static const _storageKey = 'savetep_reminders_v1';

  const LocalReminderRepository();

  @override
  Future<ReminderSnapshot?> loadSnapshot() async {
    final raw = await LocalStore.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return ReminderSnapshot(
          reminders: _mapListFrom(decoded),
          series: const [],
          deletedRecurringKeys: const [],
        );
      }
      if (decoded is! Map) return null;
      return ReminderSnapshot(
        reminders: _mapListFrom(decoded['reminders']),
        series: _mapListFrom(decoded['series']),
        deletedRecurringKeys: _stringListFrom(decoded['deletedRecurringKeys']),
      );
    } catch (_) {
      return ReminderSnapshot.empty();
    }
  }

  @override
  Future<void> saveSnapshot(ReminderSnapshot snapshot) {
    return LocalStore.write(_storageKey, jsonEncode(snapshot.toJson()));
  }
}

List<Map<String, dynamic>> _mapListFrom(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList(growable: false);
}

List<String> _stringListFrom(Object? value) {
  if (value is! List) return const [];
  return value.map((entry) => entry.toString()).toList(growable: false);
}
