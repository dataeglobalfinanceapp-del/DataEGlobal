import 'package:savetep/domain/services/employee_document_email_service.dart';

import 'employee_document_email_service_stub.dart'
    if (dart.library.html) 'employee_document_email_service_web.dart'
    as platform;

EmployeeDocumentEmailService createEmployeeDocumentEmailService() {
  return platform.createEmployeeDocumentEmailService();
}
