class MenuItemContext {
  MenuItemContext({
    required this.ok,
    required this.menuId,
    required this.businessId,
  });

  final bool ok;
  final String menuId;
  final String businessId;

  factory MenuItemContext.fromMap(Map<String, dynamic> map) {
    return MenuItemContext(
      ok: _asBool(map, ['ok']) ?? false,
      menuId: _asString(map, ['menu_id', 'menuId']) ?? '',
      businessId: _asString(map, ['business_id', 'businessId']) ?? '',
    );
  }
}

String? _asString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

bool? _asBool(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
  }
  return null;
}
