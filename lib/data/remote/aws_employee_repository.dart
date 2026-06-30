import 'dart:convert';

import 'package:savetep/core/api/aws_api_client.dart';
import 'package:savetep/data/dto/save_employee_request.dart';
import 'package:savetep/data/repositories/employee_repository.dart';
import 'package:savetep/services/app_clock.dart';

class AwsEmployeeRepository implements EmployeeRepository {
  static const _storageKey = 'employees';

  final AwsApiClient client;

  const AwsEmployeeRepository(this.client);

  @override
  Future<List<EmployeeRecord>> loadEmployees() async {
    final String? raw = await client.read(_storageKey);
    if (raw == null || raw.trim().isEmpty) return const <EmployeeRecord>[];

    final Object? decoded = jsonDecode(raw);
    final Object? employeeJson = decoded is Map
        ? decoded['employees']
        : decoded;
    if (employeeJson is! List) return const <EmployeeRecord>[];

    return employeeJson
        .whereType<Map>()
        .map(EmployeeRecord.fromJson)
        .where((EmployeeRecord employee) => employee.id.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<EmployeeRecord> saveEmployee(SaveEmployeeRequest request) async {
    final List<EmployeeRecord> employees = await loadEmployees();
    final String id = request.id.trim().isEmpty ? _newId() : request.id.trim();
    final EmployeeRecord record = EmployeeRecord.fromRequest(
      id: id,
      request: request,
    );
    final int index = employees.indexWhere(
      (EmployeeRecord employee) => employee.id == id,
    );
    final List<EmployeeRecord> updated = <EmployeeRecord>[...employees];

    if (index == -1) {
      updated.add(record);
    } else {
      updated[index] = record;
    }

    await _saveEmployees(updated);
    return record;
  }

  @override
  Future<bool> deleteEmployee(String id) async {
    final List<EmployeeRecord> employees = await loadEmployees();
    final List<EmployeeRecord> updated = employees
        .where((EmployeeRecord employee) => employee.id != id)
        .toList(growable: false);
    if (updated.length == employees.length) return false;

    await _saveEmployees(updated);
    return true;
  }

  Future<void> _saveEmployees(List<EmployeeRecord> employees) {
    return client.write(
      _storageKey,
      jsonEncode(<String, dynamic>{
        'employees': employees
            .map((EmployeeRecord employee) => employee.toJson())
            .toList(growable: false),
      }),
    );
  }

  String _newId() => 'employee-${AppClock.now.microsecondsSinceEpoch}';
}
