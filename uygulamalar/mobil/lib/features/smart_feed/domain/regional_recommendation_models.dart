class RegionalBusiness {
  const RegionalBusiness({
    required this.businessId,
    required this.businessName,
    required this.businessSlug,
    required this.logoUrl,
    required this.tagLabel,
  });

  final String businessId;
  final String businessName;
  final String businessSlug;
  final String? logoUrl;
  final String tagLabel;

  factory RegionalBusiness.fromMap(Map<String, dynamic> map) {
    return RegionalBusiness(
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      businessSlug: (map['business_slug'] ?? '').toString(),
      logoUrl: map['logo_url']?.toString(),
      tagLabel: (map['tag_label'] ?? '').toString(),
    );
  }
}
