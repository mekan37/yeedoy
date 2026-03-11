enum LocalDbBucket {
  discoveryFeed,
  businessSnapshot,
  menuSnapshot,
  offlineMutationQueue,
  telemetrySnapshot,
}

extension LocalDbBucketX on LocalDbBucket {
  String get key {
    return switch (this) {
      LocalDbBucket.discoveryFeed => 'discovery_feed',
      LocalDbBucket.businessSnapshot => 'business_snapshot',
      LocalDbBucket.menuSnapshot => 'menu_snapshot',
      LocalDbBucket.offlineMutationQueue => 'offline_mutation_queue',
      LocalDbBucket.telemetrySnapshot => 'telemetry_snapshot',
    };
  }
}

class LocalDbRecord {
  const LocalDbRecord({
    required this.bucket,
    required this.id,
    required this.payload,
    required this.updatedAt,
    this.expiresAt,
  });

  final LocalDbBucket bucket;
  final String id;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final DateTime? expiresAt;

  bool isExpired(DateTime now) {
    final limit = expiresAt;
    if (limit == null) return false;
    return !limit.isAfter(now);
  }

  LocalDbRecord copyWith({
    LocalDbBucket? bucket,
    String? id,
    Map<String, dynamic>? payload,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return LocalDbRecord(
      bucket: bucket ?? this.bucket,
      id: id ?? this.id,
      payload: payload ?? this.payload,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
