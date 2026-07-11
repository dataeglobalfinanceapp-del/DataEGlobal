import 'package:flutter/foundation.dart';

import 'package:savetep/domain/models/temporary_employee_document.dart';
import 'package:savetep/domain/models/temporary_employee_sensitive_data.dart';
import 'package:savetep/domain/services/employee_document_capture_service.dart';
import 'package:savetep/domain/services/employee_temporary_sensitive_data_service.dart';

class EmployeeCreateDraft extends ChangeNotifier {
  final EmployeeDocumentCaptureService _captureService;
  final EmployeeTemporarySensitiveDataService _sensitiveDataService;

  bool _isCapturing = false;

  EmployeeCreateDraft({
    required EmployeeDocumentCaptureService captureService,
    EmployeeTemporarySensitiveDataService? sensitiveDataService,
  }) : _captureService = captureService,
       _sensitiveDataService =
           sensitiveDataService ?? EmployeeTemporarySensitiveDataService();

  TemporaryEmployeeSensitiveData get sensitiveData =>
      _sensitiveDataService.data;

  TemporaryEmployeeDocument? get w4Document => sensitiveData.w4Document;

  bool get isCapturing => _isCapturing;

  void updateSocialSecurityNumber(String value) {
    _sensitiveDataService.updateSocialSecurityNumber(value);
    notifyListeners();
  }

  Future<EmployeeDocumentCaptureResult> captureW4Photo() async {
    if (_isCapturing) return const EmployeeDocumentCaptureResult.canceled();

    _setCapturing(true);
    try {
      final TemporaryEmployeeDocument? document = await _captureService
          .captureW4Photo();
      if (document == null) {
        return const EmployeeDocumentCaptureResult.canceled();
      }

      _sensitiveDataService.replaceW4Document(document);
      notifyListeners();
      return const EmployeeDocumentCaptureResult.captured();
    } on EmployeeDocumentCaptureException catch (error) {
      return EmployeeDocumentCaptureResult.failed(error.message);
    } finally {
      _setCapturing(false);
    }
  }

  void clearW4Document() {
    _sensitiveDataService.clearW4Document();
    notifyListeners();
  }

  void clearSensitiveData() {
    _sensitiveDataService.clearAll();
    notifyListeners();
  }

  void _setCapturing(bool value) {
    if (_isCapturing == value) return;

    _isCapturing = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _sensitiveDataService.clearAll();
    _sensitiveDataService.dispose();
    super.dispose();
  }
}

enum EmployeeDocumentCaptureStatus { captured, canceled, failed }

class EmployeeDocumentCaptureResult {
  final EmployeeDocumentCaptureStatus status;
  final String? message;

  const EmployeeDocumentCaptureResult._(this.status, {this.message});

  const EmployeeDocumentCaptureResult.captured()
    : this._(EmployeeDocumentCaptureStatus.captured);

  const EmployeeDocumentCaptureResult.canceled()
    : this._(EmployeeDocumentCaptureStatus.canceled);

  const EmployeeDocumentCaptureResult.failed(String message)
    : this._(EmployeeDocumentCaptureStatus.failed, message: message);
}
