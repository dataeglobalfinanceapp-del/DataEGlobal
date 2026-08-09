import 'package:url_launcher/url_launcher.dart';

import 'package:savetep/core/customer_service_contact.dart';

class CustomerServiceLauncher {
  const CustomerServiceLauncher();

  Future<bool> call() {
    return launchUrl(
      Uri(scheme: 'tel', path: CustomerServiceContact.dialPhone),
    );
  }
}
