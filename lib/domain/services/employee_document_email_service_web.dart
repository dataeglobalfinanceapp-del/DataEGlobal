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

    return <String>[
      'W4 information for ${request.displayEmployeeName}',
      '',
      w4Line,
    ].join('\n');
  }
}
