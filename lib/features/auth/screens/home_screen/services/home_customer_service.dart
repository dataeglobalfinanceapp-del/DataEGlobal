import 'package:savetep/services/customer_service_launcher.dart';

abstract interface class HomeCustomerService {
  Future<bool> call();
}

class LauncherHomeCustomerService implements HomeCustomerService {
  const LauncherHomeCustomerService();

  @override
  Future<bool> call() => const CustomerServiceLauncher().call();
}
