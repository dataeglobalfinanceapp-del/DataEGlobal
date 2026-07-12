import 'dart:convert';

import 'package:savetep/data/dto/save_employee_request.dart';
import 'package:savetep/data/local/default_employee_seed_data.dart';
import 'package:savetep/data/local/local_store.dart';
import 'package:savetep/data/repositories/employee_repository.dart';
import 'package:savetep/services/app_clock.dart';

class LocalEmployeeRepository implements EmployeeRepository {
  static const _storageKey = 'savetep_employee_data_v1';

  final bool disablePersistenceForTesting;
  final List<EmployeeRecord> _employees = <EmployeeRecord>[];

  int _idCounter = 0;
  int _defaultEmployeeSeedVersion = 0;
  bool _loaded;

  LocalEmployeeRepository({this.disablePersistenceForTesting = false})
    : _loaded = disablePersistenceForTesting;

  @override
  Future<List<EmployeeRecord>> loadEmployees() async {
    await _ensureLoaded();
    return List<EmployeeRecord>.unmodifiable(_employees);
  }

  @override
  Future<EmployeeRecord> saveEmployee(SaveEmployeeRequest request) async {
    await _ensureLoaded();

    final String id = request.id.trim().isEmpty ? _newId() : request.id.trim();
    final EmployeeRecord record = EmployeeRecord.fromRequest(
      id: id,
      request: request,
    );
    final int index = _employees.indexWhere(
      (EmployeeRecord employee) => employee.id == id,
    );

    if (index == -1) {
      _employees.add(record);
    } else {
      _employees[index] = record;
    }

    await _persist();
    return record;
  }

  @override
  Future<bool> deleteEmployee(String id) async {
    await _ensureLoaded();

    final int before = _employees.length;
    _employees.removeWhere((EmployeeRecord employee) => employee.id == id);
    final bool removed = _employees.length != before;
    if (removed) await _persist();
    return removed;
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;

    await EmployeeDataMigration.clearSeedEmployeeDataIfNeeded(
      employeeStorageKey: _storageKey,
      disablePersistence: disablePersistenceForTesting,
    );

    final String? raw = await LocalStore.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      await _seedDefaultEmployeesIfNeeded();
      _loaded = true;
      return;
    }

    try {
      final Object? decoded = jsonDecode(raw);
      final Object? employeeJson = decoded is Map
          ? decoded['employees']
          : decoded;
      _defaultEmployeeSeedVersion = decoded is Map
          ? _asInt(decoded['defaultEmployeeSeedVersion'])
          : 0;
      _employees
        ..clear()
        ..addAll(_employeeListFrom(employeeJson));
    } catch (_) {
      _employees.clear();
      _defaultEmployeeSeedVersion = 0;
    }

    await _seedDefaultEmployeesIfNeeded();
    _loaded = true;
  }

  Future<void> _seedDefaultEmployeesIfNeeded() async {
    if (_employees.isNotEmpty ||
        _defaultEmployeeSeedVersion >= DefaultEmployeeSeedData.version) {
      return;
    }

    _employees.addAll(
      DefaultEmployeeSeedData.employees.map(
        (SaveEmployeeRequest request) =>
            EmployeeRecord.fromRequest(id: request.id, request: request),
      ),
    );
    _defaultEmployeeSeedVersion = DefaultEmployeeSeedData.version;
    await _persist();
  }

  Future<void> _persist() async {
    if (disablePersistenceForTesting) return;

    await LocalStore.write(
      _storageKey,
      jsonEncode(<String, dynamic>{
        'defaultEmployeeSeedVersion': _defaultEmployeeSeedVersion,
        'employees': _employees
            .map((EmployeeRecord employee) => employee.toJson())
            .toList(growable: false),
      }),
    );
  }

  String _newId() {
    return 'employee-${AppClock.now.microsecondsSinceEpoch}-${_idCounter++}';
  }
}

class EmployeeDataMigration {
  static const int employeeDataSeedVersion = 1;
  static const String migrationStorageKey =
      'savetep_employee_data_seed_cleanup_version';
  static const Set<String> _legacySeedEmployeeIds = <String>{
    'employee-jack-nicholson',
    'employee-waylon-dalton',
    'employee-abdullah-lang',
    'employee-justine-henderson',
    'employee-joanna-shaffer',
    'employee-mathias-little',
  };

  const EmployeeDataMigration._();

  static Future<void> clearSeedEmployeeDataIfNeeded({
    required String employeeStorageKey,
    required bool disablePersistence,
  }) async {
    if (disablePersistence) return;

    final String? version = await LocalStore.read(migrationStorageKey);
    if (version == employeeDataSeedVersion.toString()) return;

    final String? raw = await LocalStore.read(employeeStorageKey);
    if (_containsOnlyLegacySeedEmployees(raw)) {
      await LocalStore.write(
        employeeStorageKey,
        jsonEncode(<String, dynamic>{'employees': <Object>[]}),
      );
    }
    await LocalStore.write(
      migrationStorageKey,
      employeeDataSeedVersion.toString(),
    );
  }

  static bool _containsOnlyLegacySeedEmployees(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;

    try {
      final Object? decoded = jsonDecode(raw);
      final Object? employeeJson = decoded is Map
          ? decoded['employees']
          : decoded;
      final List<EmployeeRecord> employees = _employeeListFrom(employeeJson);
      return employees.isNotEmpty &&
          employees.every(
            (EmployeeRecord employee) =>
                _legacySeedEmployeeIds.contains(employee.id),
          );
    } catch (_) {
      return false;
    }
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<EmployeeRecord> _employeeListFrom(Object? value) {
  if (value is! List) return const <EmployeeRecord>[];
  return value
      .whereType<Map>()
      .map(EmployeeRecord.fromJson)
      .where((EmployeeRecord employee) => employee.id.trim().isNotEmpty)
      .toList(growable: false);
}
