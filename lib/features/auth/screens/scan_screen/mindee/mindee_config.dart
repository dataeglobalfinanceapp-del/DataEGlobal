class MindeeConfig {
  static const String apiKey = String.fromEnvironment('MINDEE_V2_API_KEY');

  static const String expenseModelId = String.fromEnvironment(
    'MINDEE_EXPENSE_MODEL_ID',
  );

  static const String depositModelId = String.fromEnvironment(
    'MINDEE_DEPOSIT_MODEL_ID',
  );

  static const String enqueueUrl =
      'https://api-v2.mindee.net/v2/inferences/enqueue';

  const MindeeConfig._();

  static void validate({
    String apiKeyValue = apiKey,
    String expenseModelIdValue = expenseModelId,
    String depositModelIdValue = depositModelId,
  }) {
    if (apiKeyValue.trim().isEmpty) {
      throw StateError('MINDEE_V2_API_KEY is missing.');
    }

    if (expenseModelIdValue.trim().isEmpty) {
      throw StateError('MINDEE_EXPENSE_MODEL_ID is missing.');
    }

    if (depositModelIdValue.trim().isEmpty) {
      throw StateError('MINDEE_DEPOSIT_MODEL_ID is missing.');
    }
  }
}

class MindeePollingOptions {
  static const Duration initialDelay = Duration(seconds: 3);
  static const Duration pollingDelay = Duration(milliseconds: 1500);
  static const Duration timeout = Duration(seconds: 90);

  const MindeePollingOptions._();
}
