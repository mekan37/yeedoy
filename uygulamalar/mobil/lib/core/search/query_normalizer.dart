// Her aramada (her tuş vuruşunda) yeniden derlenmesin diye modül seviyesinde
// bir kez derleniyor (B64).
final _nonAlphaNumeric = RegExp(r'[^a-z0-9\s]');
final _extraWhitespace = RegExp(r'\s+');

String normalizeSearchQuery(String input) {
  var value = input.trim().toLowerCase();
  if (value.isEmpty) return '';

  const replacements = <String, String>{
    '\u0131': 'i', // dotless i
    '\u00f6': 'o', // ö
    '\u00fc': 'u', // ü
    '\u015f': 's', // ş
    '\u00e7': 'c', // ç
    '\u011f': 'g', // ğ
    '\u00e2': 'a', // â
    '\u00ee': 'i', // î
    '\u00fb': 'u', // û
  };

  for (final entry in replacements.entries) {
    value = value.replaceAll(entry.key, entry.value);
  }

  value = value.replaceAll(_nonAlphaNumeric, ' ');
  value = value.replaceAll(_extraWhitespace, ' ').trim();
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
