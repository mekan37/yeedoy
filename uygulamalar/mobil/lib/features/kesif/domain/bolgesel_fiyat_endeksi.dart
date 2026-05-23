class RegionalPriceIndexItem {
  const RegionalPriceIndexItem({
    required this.category,
    required this.medianPriceCents,
    required this.avgPriceCents,
    required this.sampleCount,
    required this.updatedIn30d,
  });

  final String category;
  final int medianPriceCents;
  final int avgPriceCents;
  final int sampleCount;
  final int updatedIn30d;

  factory RegionalPriceIndexItem.fromMap(Map<String, dynamic> map) {
    return RegionalPriceIndexItem(
      category: (map['category'] ?? '').toString(),
      medianPriceCents: ((map['median_price_cents'] as num?) ?? 0).toInt(),
      avgPriceCents: ((map['avg_price_cents'] as num?) ?? 0).toInt(),
      sampleCount: ((map['sample_count'] as num?) ?? 0).toInt(),
      updatedIn30d: ((map['updated_in_30d'] as num?) ?? 0).toInt(),
    );
  }
}
