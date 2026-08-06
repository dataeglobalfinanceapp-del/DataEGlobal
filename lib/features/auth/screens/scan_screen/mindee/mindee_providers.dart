import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../deposit_screen/deposit_mindee_mapper.dart';
import '../expense_screen/expense_mindee_mapper.dart';
import 'document_analysis_service.dart';

typedef MindeeHttpClientFactory = http.Client Function();

final mindeeHttpClientFactoryProvider = Provider<MindeeHttpClientFactory>((
  ref,
) {
  return http.Client.new;
});

final mindeeHttpClientProvider = Provider<http.Client>((ref) {
  final client = ref.watch(mindeeHttpClientFactoryProvider)();
  ref.onDispose(client.close);
  return client;
});

final documentAnalysisServiceProvider = Provider<DocumentAnalysisService>((
  ref,
) {
  return MindeeDocumentAnalysisService(
    httpClient: ref.watch(mindeeHttpClientProvider),
  );
});

final expenseMindeeMapperProvider = Provider<ExpenseMindeeMapper>((ref) {
  return const ExpenseMindeeMapper();
});

final depositMindeeMapperProvider = Provider<DepositMindeeMapper>((ref) {
  return const DepositMindeeMapper();
});
