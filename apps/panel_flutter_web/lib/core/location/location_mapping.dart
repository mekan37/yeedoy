String _normalizeForCompare(String input) {
  var text = input.trim().toLowerCase();
  const trMap = {
    'ç': 'c',
    'ğ': 'g',
    'ı': 'i',
    'İ': 'i',
    'ö': 'o',
    'ş': 's',
    'ü': 'u',
  };
  trMap.forEach((k, v) {
    text = text.replaceAll(k, v);
  });
  return text.replaceAll(RegExp(r'\s+'), ' ');
}

String _titleCaseTr(String input) {
  final words = input.trim().split(RegExp(r'\s+'));
  return words
      .where((w) => w.isNotEmpty)
      .map((w) {
        final first = w[0].toUpperCase();
        final rest = w.length > 1 ? w.substring(1).toLowerCase() : '';
        return '$first$rest';
      })
      .join(' ');
}

String canonicalCity(String city) {
  final raw = city.trim();
  if (raw.isEmpty) return raw;
  final key = _normalizeForCompare(raw);
  const aliases = <String, String>{
    'istanbul': 'İstanbul',
    'istanbul avrupa': 'İstanbul',
    'istanbul anadolu': 'İstanbul',
    'ankara': 'Ankara',
    'izmir': 'İzmir',
    'bursa': 'Bursa',
    'antalya': 'Antalya',
  };
  return aliases[key] ?? _titleCaseTr(raw);
}

String canonicalDistrict(String district) {
  final raw = district.trim();
  if (raw.isEmpty) return raw;
  return _titleCaseTr(raw);
}

({String city, String district}) canonicalCityDistrict(
  String city,
  String district,
) {
  return (city: canonicalCity(city), district: canonicalDistrict(district));
}

bool locationContainsQuery({
  required String city,
  required String district,
  required String query,
}) {
  final q = _normalizeForCompare(query);
  if (q.isEmpty) return true;
  final c = _normalizeForCompare(city);
  final d = _normalizeForCompare(district);
  return c.contains(q) || d.contains(q);
}

