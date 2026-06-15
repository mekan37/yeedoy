class NearbyCampaign {
  NearbyCampaign({
    required this.storyId,
    required this.businessId,
    required this.businessName,
    required this.city,
    required this.district,
    required this.caption,
    required this.mediaThumbUrl,
    required this.expiresAt,
    this.distanceKm,
    this.discountPercent,
    this.category,
    this.isFeatured = false,
    this.isSaved = false,
  });

  final String storyId;
  final String businessId;
  final String businessName;
  final String? city;
  final String? district;
  final String? caption;
  final String mediaThumbUrl;
  final DateTime expiresAt;
  final double? distanceKm;
  final int? discountPercent;
  final String? category;
  final bool isFeatured;
  final bool isSaved;

  factory NearbyCampaign.fromMap(Map<String, dynamic> map) {
    return NearbyCampaign(
      storyId: (map['story_id'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      city: map['city']?.toString(),
      district: map['district']?.toString(),
      caption: map['caption']?.toString(),
      mediaThumbUrl: (map['media_thumb_url'] ?? map['media_url'] ?? '')
          .toString(),
      expiresAt:
          DateTime.tryParse((map['expires_at'] ?? '').toString()) ??
          DateTime.now(),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      discountPercent: (map['discount_percent'] as num?)?.toInt(),
      category: map['category']?.toString(),
      isFeatured: map['is_featured'] == true,
      isSaved: map['is_saved'] == true,
    );
  }

  NearbyCampaign copyWith({bool? isSaved}) {
    return NearbyCampaign(
      storyId: storyId,
      businessId: businessId,
      businessName: businessName,
      city: city,
      district: district,
      caption: caption,
      mediaThumbUrl: mediaThumbUrl,
      expiresAt: expiresAt,
      distanceKm: distanceKm,
      discountPercent: discountPercent,
      category: category,
      isFeatured: isFeatured,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

enum CampaignFilter { all, soon, today, food, dessert, discount20 }

List<NearbyCampaign> applyCampaignFilter(
  List<NearbyCampaign> items,
  CampaignFilter filter, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  switch (filter) {
    case CampaignFilter.all:
      return items;
    case CampaignFilter.soon:
      return items
          .where(
            (c) =>
                c.expiresAt.difference(reference) <= const Duration(hours: 24),
          )
          .toList();
    case CampaignFilter.today:
      return items.where((c) {
        final expires = c.expiresAt;
        return expires.year == reference.year &&
            expires.month == reference.month &&
            expires.day == reference.day;
      }).toList();
    case CampaignFilter.food:
      return items.where((c) => c.category == 'yemek').toList();
    case CampaignFilter.dessert:
      return items.where((c) => c.category == 'tatli').toList();
    case CampaignFilter.discount20:
      return items
          .where(
            (c) => c.discountPercent != null && c.discountPercent! >= 20,
          )
          .toList();
  }
}

List<NearbyCampaign> toggleCampaignSavedInList(
  List<NearbyCampaign> items,
  String storyId,
  bool saved,
) {
  return [
    for (final item in items)
      if (item.storyId == storyId) item.copyWith(isSaved: saved) else item,
  ];
}
