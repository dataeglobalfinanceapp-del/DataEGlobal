class ReminderSnapshot {
  final List<Map<String, dynamic>> reminders;
  final List<Map<String, dynamic>> series;
  final List<String> deletedRecurringKeys;

  ReminderSnapshot({
    required Iterable<Map<String, dynamic>> reminders,
    required Iterable<Map<String, dynamic>> series,
    required Iterable<String> deletedRecurringKeys,
  }) : reminders = _immutableMapList(reminders),
       series = _immutableMapList(series),
       deletedRecurringKeys = List.unmodifiable(deletedRecurringKeys);

  ReminderSnapshot.empty()
    : reminders = const [],
      series = const [],
      deletedRecurringKeys = const [];

  Map<String, dynamic> toJson() {
    return {
      'reminders': reminders,
      'series': series,
      'deletedRecurringKeys': deletedRecurringKeys,
    };
  }
}

abstract class ReminderRepository {
  Future<ReminderSnapshot?> loadSnapshot();

  Future<void> saveSnapshot(ReminderSnapshot snapshot);
}

List<Map<String, dynamic>> _immutableMapList(
  Iterable<Map<String, dynamic>> values,
) {
  return List.unmodifiable(
    values.map<Map<String, dynamic>>(
      (value) => Map<String, dynamic>.unmodifiable(value),
    ),
  );
}
