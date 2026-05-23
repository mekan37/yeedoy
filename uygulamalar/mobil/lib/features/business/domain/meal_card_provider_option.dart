class MealCardProviderOption {
  MealCardProviderOption({
    required this.id,
    required this.key,
    required this.name,
    required this.assetName,
    required this.sortOrder,
  });

  final String id;
  final String key;
  final String name;
  final String assetName;
  final int sortOrder;

  factory MealCardProviderOption.fromMap(Map<String, dynamic> map) {
    return MealCardProviderOption(
      id: (map['provider_id'] ?? map['id'] ?? '').toString(),
      key: (map['key'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      assetName: (map['asset_name'] ?? '').toString(),
      sortOrder: ((map['sort_order'] as num?) ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'provider_id': id,
    'key': key,
    'name': name,
    'asset_name': assetName,
    'sort_order': sortOrder,
  };
}
