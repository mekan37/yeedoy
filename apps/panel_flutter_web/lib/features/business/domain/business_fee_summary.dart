class BusinessFeeFieldSummary {
  BusinessFeeFieldSummary({
    required this.value,
    required this.confidence,
    required this.total,
  });

  final bool? value;
  final double confidence;
  final int total;

  factory BusinessFeeFieldSummary.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return BusinessFeeFieldSummary(value: null, confidence: 0, total: 0);
    }
    return BusinessFeeFieldSummary(
      value: map['value'] as bool?,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class BusinessFeeSummary {
  BusinessFeeSummary({
    required this.cover,
    required this.service,
    required this.water,
  });

  final BusinessFeeFieldSummary cover;
  final BusinessFeeFieldSummary service;
  final BusinessFeeFieldSummary water;

  factory BusinessFeeSummary.fromMap(Map<String, dynamic> map) {
    return BusinessFeeSummary(
      cover: BusinessFeeFieldSummary.fromMap(map['cover'] as Map<String, dynamic>?),
      service: BusinessFeeFieldSummary.fromMap(map['service'] as Map<String, dynamic>?),
      water: BusinessFeeFieldSummary.fromMap(map['water'] as Map<String, dynamic>?),
    );
  }

  bool get isEmpty =>
      cover.total == 0 && service.total == 0 && water.total == 0;
}
