class CategoryAssets {
  const CategoryAssets._();

  static const String defaultAsset = 'assets/images/categories/default.webp';

  static const Map<String, String> bySlug = {
    'kafe': 'assets/images/categories/cafe.webp',
    'cafe': 'assets/images/categories/cafe.webp',
    'restoran': 'assets/images/categories/restoran.webp',
    'restaurant': 'assets/images/categories/restoran.webp',
    'tatlici': 'assets/images/categories/tatlici.webp',
    'dessert': 'assets/images/categories/tatlici.webp',
    'kahvalti': 'assets/images/categories/kahvalti.webp',
    'breakfast': 'assets/images/categories/kahvalti.webp',
    'balik': 'assets/images/categories/balik-et.webp',
    'fish': 'assets/images/categories/balik-et.webp',
    'et': 'assets/images/categories/balik-et.webp',
    'meat': 'assets/images/categories/balik-et.webp',
    'balik et': 'assets/images/categories/balik-et.webp',
    'fish meat': 'assets/images/categories/balik-et.webp',
    'mekan': 'assets/images/categories/mekan.webp',
    'venue': 'assets/images/categories/mekan.webp',
  };

  static String resolve(String? categorySlugOrName) {
    final key = _normalize(categorySlugOrName);
    return bySlug[key] ?? defaultAsset;
  }

  static String _normalize(String? value) {
    if (value == null) return '';
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
