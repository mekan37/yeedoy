class NearbyCampaign {
  NearbyCampaign({
    required this.businessId,
    required this.businessName,
    required this.city,
    required this.district,
    required this.caption,
    required this.mediaThumbUrl,
    required this.expiresAt,
    this.distanceKm,
  });

  final String businessId;
  final String businessName;
  final String? city;
  final String? district;
  final String? caption;
  final String mediaThumbUrl;
  final DateTime expiresAt;
  final double? distanceKm;

  factory NearbyCampaign.fromMap(Map<String, dynamic> map) {
    return NearbyCampaign(
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
    );
  }
}
