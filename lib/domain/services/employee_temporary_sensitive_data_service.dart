import 'package:flutter/foundation.dart';

import 'package:savetep/domain/models/temporary_employee_document.dart';
import 'package:savetep/domain/models/temporary_employee_sensitive_data.dart';
import 'package:savetep/domain/services/employee_document_repository.dart';

class EmployeeTemporarySensitiveDataService extends ChangeNotifier {
  final EmployeeDocumentRepository _repository;

  EmployeeTemporarySensitiveDataService({
    EmployeeDocumentRepository? repository,
  }) : _repository = repository ?? InMemoryEmployeeDocumentRepository();

  TemporaryEmployeeSensitiveData get data => _repository.sensitiveData;

  TemporaryEmployeeDocument? get w4Document => data.w4Document;

  bool get hasSensitiveData =>
      data.hasSocialSecurityNumber || data.hasW4Document;

  void updateSocialSecurityNumber(String value) {
    _save(data.copyWith(socialSecurityNumber: value.trim()));
  }

  void replaceW4Document(TemporaryEmployeeDocument document) {
    _save(data.copyWith(w4Document: document));
  }

  void clearW4Document() {
    if (!data.hasW4Document) return;

    _save(data.copyWith(clearW4Document: true));
  }

  void clearAll() {
    if (!hasSensitiveData) return;

    _repository.clearSensitiveData();
    notifyListeners();
  }

  void _save(TemporaryEmployeeSensitiveData data) {
    _repository.saveSensitiveData(data);
    notifyListeners();
  }
}
