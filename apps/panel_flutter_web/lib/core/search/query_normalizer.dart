String normalizeSearchQuery(String input) {
  var value = input.trim().toLowerCase();
  if (value.isEmpty) return '';

  const map = <String, String>{
    'ı': 'i',
    'İ': 'i',
    'ö': 'o',
    'ü': 'u',
    'ş': 's',
    'ç': 'c',
    'ğ': 'g',
    'â': 'a',
    'î': 'i',
    'û': 'u',
  };
  for (final entry in map.entries) {
    value = value.replaceAll(entry.key.toLowerCase(), entry.value);
  }
  value = value.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  return value;
}

List<String> buildSearchVariants(String query) {
  final raw = query.trim().toLowerCase();
  if (raw.isEmpty) return const [''];

  final normalized = normalizeSearchQuery(raw);
  final variants = <String>{raw, normalized};

  const synonyms = <String, List<String>>{
    'doner': ['doner', 'donerci', 'iskender'],
    'kahvalti': ['kahvalti', 'brunch', 'serpme'],
    'kebap': ['kebap', 'ocakbasi', 'mangal'],
    'corba': ['corba', 'corbaci'],
    'tatli': ['tatli', 'pastane', 'dessert'],
    'burger': ['burger', 'hamburger'],
  };

  for (final entry in synonyms.entries) {
    if (normalized.contains(entry.key)) {
      variants.addAll(entry.value);
    }
  }

  return variants.where((e) => e.trim().isNotEmpty).toList();
}
