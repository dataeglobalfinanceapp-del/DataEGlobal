import 'package:web/web.dart' as web;

import 'package:savetep/domain/services/employee_document_email_service.dart';

EmployeeDocumentEmailService createEmployeeDocumentEmailService() {
  return const MailtoEmployeeDocumentEmailService();
}

class MailtoEmployeeDocumentEmailService
    implements EmployeeDocumentEmailService {
  const MailtoEmployeeDocumentEmailService();

  @override
  Future<void> sendW4Email(W4EmailRequest request) async {
    final Uri mailtoUri = Uri(
      scheme: 'mailto',
      path: request.normalizedRecipientEmail,
      queryParameters: <String, String>{
        'subject': 'W4 information for ${request.displayEmployeeName}',
        'body': _bodyFor(request),
      },
    );

    web.window.location.href = mailtoUri.toString();
  }

  String _bodyFor(W4EmailRequest request) {
    final String link = request.linkW4.trim();
    final String w4Line = link.isEmpty
        ? 'W4 Link: Not provided'
        : 'W4 Link: $link';
    final String photoLine = request.hasTemporaryDocument
        ? 'W4 Photo: ${request.temporaryDocument!.fileName}'
        : 'W4 Photo: Not provided';
    final String ssnLine = request.hasSocialSecurityNumber
        ? 'Social Security Number: ${request.sensitiveData.formattedSocialSecurityNumber}'
        : 'Social Security Number: Not provided';
    final W4EmailEmployeeDetails details = request.employeeDetails;

    return <String>[
      'W4 information for ${request.displayEmployeeName}',
      '',
      'Employee Details',
      'Full Name: ${details.fullName}',
      'Rate: \$${details.rate.toStringAsFixed(2)}',
      'Address: ${details.address}',
      if (details.jobType.trim().isNotEmpty) 'Job Type: ${details.jobType}',
      if (details.phone.trim().isNotEmpty) 'Phone: ${details.phone}',
      if (details.birthday.trim().isNotEmpty) 'Birthday: ${details.birthday}',
      if (details.dateHire.trim().isNotEmpty) 'Date Hire: ${details.dateHire}',
      if (details.payMethod.trim().isNotEmpty)
        'Pay Method: ${details.payMethod}',
      '',
      w4Line,
      photoLine,
      ssnLine,
    ].join('\n');
  }
}
