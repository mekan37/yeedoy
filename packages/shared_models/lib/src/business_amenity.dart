class BusinessAmenity {
  BusinessAmenity({
    required this.id,
    required this.key,
    required this.label,
    required this.icon,
  });

  final String id;
  final String key;
  final String label;
  final String icon;

  factory BusinessAmenity.fromMap(Map<String, dynamic> m) => BusinessAmenity(
        id: (m['amenity_id'] ?? m['id'] ?? '').toString(),
        key: (m['key'] ?? '').toString(),
        label: (m['label'] ?? '').toString(),
        icon: (m['icon'] ?? '').toString(),
      );
}
