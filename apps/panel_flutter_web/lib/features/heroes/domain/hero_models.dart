class HeroEntry {
  HeroEntry({
    required this.userId,
    required this.donatedCount,
    required this.totalCents,
    required this.currency,
  });

  final String userId;
  final int donatedCount;
  final int totalCents;
  final String currency;

  factory HeroEntry.fromMap(Map<String, dynamic> map) {
    return HeroEntry(
      userId: (map['user_id'] ?? '').toString(),
      donatedCount: (map['donated_count'] as num?)?.toInt() ?? 0,
      totalCents: (map['total_cents'] as num?)?.toInt() ??
          (map['total_amount_cents'] as num?)?.toInt() ??
          0,
      currency: (map['currency'] ?? 'TRY').toString(),
    );
  }
}
