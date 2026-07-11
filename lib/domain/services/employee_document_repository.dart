import 'package:savetep/domain/models/temporary_employee_sensitive_data.dart';

abstract class EmployeeDocumentRepository {
  const EmployeeDocumentRepository();

  TemporaryEmployeeSensitiveData get sensitiveData;

  void saveSensitiveData(TemporaryEmployeeSensitiveData data);

  void clearSensitiveData();
}

class InMemoryEmployeeDocumentRepository implements EmployeeDocumentRepository {
  TemporaryEmployeeSensitiveData _sensitiveData =
      const TemporaryEmployeeSensitiveData();

  @override
  TemporaryEmployeeSensitiveData get sensitiveData => _sensitiveData;

  @override
  void saveSensitiveData(TemporaryEmployeeSensitiveData data) {
    _sensitiveData = data;
  }

  @override
  void clearSensitiveData() {
    _sensitiveData = const TemporaryEmployeeSensitiveData();
  }
}
