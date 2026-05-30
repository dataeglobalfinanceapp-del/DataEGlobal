import 'dart:convert';

import 'app_clock.dart';
import '../services/local_store_test/local_store.dart';

enum ReminderDeleteScope { single, series }

enum ReminderEditScope { single, series }

class ReminderService {
  static const _storageKey = 'biztrack_reminders_v1';

  static final List<ReminderRecord> _reminders = [];
  static final Map<String, ReminderSeries> _series = {};
  static final Set<String> _deletedRecurringKeys = {};
  static int _idCounter = 0;
  static bool _loaded = false;

  static Future<List<ReminderRecord>> loadReminders() async {
    await _ensureLoaded();
    final records = List<ReminderRecord>.from(_reminders);
    records.sort((a, b) => a.date.compareTo(b.date));
    return List.unmodifiable(records);
  }

  static Future<void> saveReminders(List<ReminderDraft> drafts) async {
    await _ensureLoaded();
    final now = AppClock.now;

    for (final draft in drafts) {
      if (draft.amount <= 0) continue;

      if (_isRecurringCount(draft.reminderCount)) {
        final series = ReminderSeries(
          id: _newId('reminder-series'),
          startDate: _dateOnly(draft.date),
          category: draft.category,
          amount: draft.amount,
          reminderCount: draft.reminderCount,
          payee: draft.payee.isEmpty ? draft.category : draft.payee,
          alertEnabled: true,
          createdAt: now,
        );
        _series[series.id] = series;
        _addMissingOccurrencesForSeries(
          series,
          upToYear: _maxInt(now.year, series.startDate.year),
        );
      } else {
        _reminders.add(
          ReminderRecord(
            id: _newId('reminder'),
            date: _dateOnly(draft.date),
            category: draft.category,
            amount: draft.amount,
            reminderCount: draft.reminderCount,
            payee: draft.payee.isEmpty ? draft.category : draft.payee,
            alertEnabled: true,
            createdAt: now,
          ),
        );
      }
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

  static Future<void> updateAmount(
    String id,
    double amount, {
    ReminderEditScope scope = ReminderEditScope.single,
  }) async {
    if (amount <= 0) return;
    await _ensureLoaded();
    final index = _reminders.indexWhere((record) => record.id == id);
    if (index == -1) return;
    final record = _reminders[index];

    if (scope == ReminderEditScope.series && record.isRecurring) {
      final series = _series[record.recurringSeriesId];
      if (series != null) {
        _series[series.id] = series.copyWith(amount: amount);
      }
      for (var i = 0; i < _reminders.length; i++) {
        if (_reminders[i].recurringSeriesId == record.recurringSeriesId) {
          _reminders[i] = _reminders[i].copyWith(amount: amount);
        }
      }
    } else {
      _reminders[index] = record.copyWith(amount: amount);
    }

    await _persist();
  }

  static Future<bool> deleteReminder(
    String id, {
    ReminderDeleteScope scope = ReminderDeleteScope.single,
  }) async {
    await _ensureLoaded();
    final index = _reminders.indexWhere((record) => record.id == id);
    if (index == -1) return false;
    final record = _reminders[index];

    if (scope == ReminderDeleteScope.series && record.isRecurring) {
      final seriesId = record.recurringSeriesId;
      _series.remove(seriesId);
      _reminders.removeWhere((entry) => entry.recurringSeriesId == seriesId);
      _deletedRecurringKeys.removeWhere((key) => key.startsWith('$seriesId|'));
    } else {
      if (record.isRecurring) {
        _deletedRecurringKeys.add(record.recurringOccurrenceKey);
      }
      _reminders.removeAt(index);
    }

    await _persist();
    return true;
  }

  static Future<void> postpone(String id, {int days = 1}) async {
    await _ensureLoaded();
    final index = _reminders.indexWhere((record) => record.id == id);
    if (index == -1) return;
    final record = _reminders[index];
    if (record.isRecurring) {
      _deletedRecurringKeys.add(record.recurringOccurrenceKey);
    }
    _reminders[index] = record.copyWith(
      date: _dateOnly(record.date.add(Duration(days: days))),
    );
    await _persist();
  }

  static Future<void> _ensureLoaded() async {
    if (_loaded) {
      final changed = _syncRecurringReminders(AppClock.now);
      if (changed) await _persist();
      return;
    }

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
      } else if (decoded is Map) {
        _reminders
          ..clear()
          ..addAll(
            _listFromJson(decoded['reminders']).map(ReminderRecord.fromJson),
          );
        _series
          ..clear()
          ..addEntries(
            _listFromJson(decoded['series'])
                .map(ReminderSeries.fromJson)
                .map((entry) => MapEntry(entry.id, entry)),
          );
        _deletedRecurringKeys
          ..clear()
          ..addAll(_stringListFromJson(decoded['deletedRecurringKeys']));
      }
    } catch (_) {
      _reminders.clear();
      _series.clear();
      _deletedRecurringKeys.clear();
    }

    _loaded = true;
    final repaired = _repairRecurringData();
    final synced = _syncRecurringReminders(AppClock.now);
    final changed = repaired || synced;
    if (changed) await _persist();
  }

  static Future<void> _persist() async {
    final payload = jsonEncode({
      'reminders': _reminders.map((record) => record.toJson()).toList(),
      'series': _series.values.map((record) => record.toJson()).toList(),
      'deletedRecurringKeys': _deletedRecurringKeys.toList(),
    });
    await LocalStore.write(_storageKey, payload);
  }

  static bool _repairRecurringData() {
    var changed = false;

    for (var i = 0; i < _reminders.length; i++) {
      final record = _reminders[i];
      if (!_isRecurringCount(record.reminderCount)) continue;

      var seriesId = record.recurringSeriesId;
      if (seriesId.isEmpty) {
        seriesId = _newId('reminder-series-imported');
        changed = true;
      }

      final occurrenceKey = record.recurringOccurrenceKey.isEmpty
          ? _occurrenceKey(seriesId, _dateOnly(record.date))
          : record.recurringOccurrenceKey;

      if (seriesId != record.recurringSeriesId ||
          occurrenceKey != record.recurringOccurrenceKey) {
        _reminders[i] = record.copyWith(
          recurringSeriesId: seriesId,
          recurringOccurrenceKey: occurrenceKey,
        );
        changed = true;
      }

      _series.putIfAbsent(seriesId, () {
        changed = true;
        return ReminderSeries.fromRecord(_reminders[i]);
      });
    }

    for (final seriesId in _series.keys.toList()) {
      final hasRecord = _reminders.any(
        (record) => record.recurringSeriesId == seriesId,
      );
      if (!hasRecord) {
        _series.remove(seriesId);
        _deletedRecurringKeys.removeWhere(
          (key) => key.startsWith('$seriesId|'),
        );
        changed = true;
      }
    }

    return changed;
  }

  static bool _syncRecurringReminders(DateTime now) {
    var changed = _repairRecurringData();
    final upToYear = now.year;

    for (final series in _series.values.toList()) {
      if (series.startDate.year > upToYear) {
        changed =
            _addMissingOccurrencesForSeries(
              series,
              upToYear: series.startDate.year,
            ) ||
            changed;
      } else {
        changed =
            _addMissingOccurrencesForSeries(series, upToYear: upToYear) ||
            changed;
      }
    }

    return changed;
  }

  static bool _addMissingOccurrencesForSeries(
    ReminderSeries series, {
    required int upToYear,
  }) {
    var changed = false;

    for (var year = series.startDate.year; year <= upToYear; year++) {
      for (final date in _occurrenceDatesForYear(series, year)) {
        final occurrenceKey = _occurrenceKey(series.id, date);
        if (_deletedRecurringKeys.contains(occurrenceKey)) continue;
        if (_reminders.any(
          (record) => record.recurringOccurrenceKey == occurrenceKey,
        )) {
          continue;
        }

        _reminders.add(
          ReminderRecord(
            id: _newId('reminder-${series.id}-${date.year}-${date.month}'),
            date: date,
            category: series.category,
            amount: series.amount,
            reminderCount: series.reminderCount,
            payee: series.payee,
            alertEnabled: series.alertEnabled,
            createdAt: series.createdAt,
            recurringSeriesId: series.id,
            recurringOccurrenceKey: occurrenceKey,
          ),
        );
        changed = true;
      }
    }

    return changed;
  }

  static List<DateTime> _occurrenceDatesForYear(
    ReminderSeries series,
    int year,
  ) {
    if (year < series.startDate.year) return [];

    final startOfYear = DateTime(year);
    final endOfYear = DateTime(year, 12, 31);
    final frequency = series.reminderCount.toLowerCase();

    if (frequency == 'weekly') {
      var date = series.startDate;
      if (date.isBefore(startOfYear)) {
        final difference = startOfYear.difference(date).inDays;
        final offset = difference % 7 == 0 ? 0 : 7 - (difference % 7);
        date = startOfYear.add(Duration(days: offset));
      }

      final dates = <DateTime>[];
      while (!date.isAfter(endOfYear)) {
        dates.add(_dateOnly(date));
        date = date.add(const Duration(days: 7));
      }
      return dates;
    }

    final intervalMonths = switch (frequency) {
      'monthly' => 1,
      'quarterly' => 3,
      'yearly' => 12,
      _ => 0,
    };
    if (intervalMonths == 0) return [];

    final dates = <DateTime>[];
    for (var index = 0; index < 1200; index++) {
      final date = _addMonthsClamped(series.startDate, index * intervalMonths);
      if (date.year > year) break;
      if (date.year == year) dates.add(date);
    }
    return dates;
  }

  static DateTime _addMonthsClamped(DateTime date, int months) {
    final totalMonths = date.year * 12 + date.month - 1 + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final day = _minInt(date.day, _daysInMonth(year, month));
    return DateTime(year, month, day);
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static String _occurrenceKey(String seriesId, DateTime date) {
    final value = _dateOnly(date);
    return '$seriesId|${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isRecurringCount(String value) {
    return switch (value.trim().toLowerCase()) {
      'weekly' || 'monthly' || 'quarterly' || 'yearly' => true,
      _ => false,
    };
  }

  static int _maxInt(int a, int b) => a > b ? a : b;

  static int _minInt(int a, int b) => a < b ? a : b;

  static List<Map<String, dynamic>> _listFromJson(Object? value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  static List<String> _stringListFromJson(Object? value) {
    if (value is! List) return [];
    return value.map((entry) => entry.toString()).toList();
  }

  static String _newId(String prefix) =>
      '$prefix-${AppClock.now.microsecondsSinceEpoch}-${_idCounter++}';
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

class ReminderSeries {
  final String id;
  final DateTime startDate;
  final String category;
  final double amount;
  final String reminderCount;
  final String payee;
  final bool alertEnabled;
  final DateTime createdAt;

  const ReminderSeries({
    required this.id,
    required this.startDate,
    required this.category,
    required this.amount,
    required this.reminderCount,
    required this.payee,
    required this.alertEnabled,
    required this.createdAt,
  });

  factory ReminderSeries.fromJson(Map<dynamic, dynamic> json) {
    return ReminderSeries(
      id: _asString(json['id'], fallback: _fallbackId('reminder-series')),
      startDate: _asDate(json['startDate']),
      category: _asString(json['category'], fallback: 'Reminder'),
      amount: _asDouble(json['amount']),
      reminderCount: _asString(json['reminderCount'], fallback: 'Monthly'),
      payee: _asString(json['payee'], fallback: 'Reminder'),
      alertEnabled: json['alertEnabled'] != false,
      createdAt: _asDate(json['createdAt']),
    );
  }

  factory ReminderSeries.fromRecord(ReminderRecord record) {
    return ReminderSeries(
      id: record.recurringSeriesId,
      startDate: record.date,
      category: record.category,
      amount: record.amount,
      reminderCount: record.reminderCount,
      payee: record.payee,
      alertEnabled: record.alertEnabled,
      createdAt: record.createdAt,
    );
  }

  ReminderSeries copyWith({double? amount}) {
    return ReminderSeries(
      id: id,
      startDate: startDate,
      category: category,
      amount: amount ?? this.amount,
      reminderCount: reminderCount,
      payee: payee,
      alertEnabled: alertEnabled,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startDate': startDate.toIso8601String(),
    'category': category,
    'amount': amount,
    'reminderCount': reminderCount,
    'payee': payee,
    'alertEnabled': alertEnabled,
    'createdAt': createdAt.toIso8601String(),
  };
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
  final String recurringSeriesId;
  final String recurringOccurrenceKey;

  const ReminderRecord({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    required this.reminderCount,
    required this.payee,
    required this.alertEnabled,
    required this.createdAt,
    this.recurringSeriesId = '',
    this.recurringOccurrenceKey = '',
  });

  factory ReminderRecord.fromJson(Map<dynamic, dynamic> json) {
    final seriesId = _asString(json['recurringSeriesId']);
    final date = _asDate(json['date']);
    return ReminderRecord(
      id: _asString(json['id'], fallback: _fallbackId('reminder')),
      date: date,
      category: _asString(json['category'], fallback: 'Reminder'),
      amount: _asDouble(json['amount']),
      reminderCount: _asString(json['reminderCount'], fallback: 'Just one'),
      payee: _asString(json['payee'], fallback: 'Reminder'),
      alertEnabled: json['alertEnabled'] != false,
      createdAt: _asDate(json['createdAt']),
      recurringSeriesId: seriesId,
      recurringOccurrenceKey: _asString(json['recurringOccurrenceKey']),
    );
  }

  bool get isRecurring => recurringSeriesId.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'category': category,
    'amount': amount,
    'reminderCount': reminderCount,
    'payee': payee,
    'alertEnabled': alertEnabled,
    'createdAt': createdAt.toIso8601String(),
    'recurringSeriesId': recurringSeriesId,
    'recurringOccurrenceKey': recurringOccurrenceKey,
  };

  ReminderRecord copyWith({
    DateTime? date,
    String? category,
    double? amount,
    String? reminderCount,
    String? payee,
    bool? alertEnabled,
    String? recurringSeriesId,
    String? recurringOccurrenceKey,
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
      recurringSeriesId: recurringSeriesId ?? this.recurringSeriesId,
      recurringOccurrenceKey:
          recurringOccurrenceKey ?? this.recurringOccurrenceKey,
    );
  }
}

int _fallbackIdCounter = 0;

String _fallbackId(String prefix) =>
    '$prefix-imported-${AppClock.now.microsecondsSinceEpoch}-${_fallbackIdCounter++}';

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
  return DateTime.tryParse(value?.toString() ?? '') ?? AppClock.now;
}
