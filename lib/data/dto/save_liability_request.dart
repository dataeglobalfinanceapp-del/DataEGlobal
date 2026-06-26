import 'package:savetep/features/auth/models/liability_model.dart';

class SaveLiabilityRequest {
  final LiabilityTab tab;
  final String name;
  final DateTime date;
  final double starting;
  final double minimum;
  final int percent;
  final String source;

  const SaveLiabilityRequest({
    required this.tab,
    required this.name,
    required this.date,
    required this.starting,
    required this.minimum,
    required this.percent,
    this.source = 'manual',
  });

  Map<String, dynamic> toJson() => {
    'tab': tab.name,
    'name': name,
    'date': date.toIso8601String(),
    'starting': starting,
    'minimum': minimum,
    'percent': percent,
    'source': source,
  };
}
