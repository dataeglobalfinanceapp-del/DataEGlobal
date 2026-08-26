class AuthSignUpAttempt {
  final bool needsConfirmation;
  final AuthCodeDeliveryInfo? codeDelivery;

  const AuthSignUpAttempt({
    required this.needsConfirmation,
    required this.codeDelivery,
  });
}

class AuthCodeDeliveryInfo {
  final String destination;
  final String deliveryMedium;

  const AuthCodeDeliveryInfo({
    required this.destination,
    required this.deliveryMedium,
  });

  String get message =>
      'Code sent to $destination by ${deliveryMedium.toLowerCase()}';
}
