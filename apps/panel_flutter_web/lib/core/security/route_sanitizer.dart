final RegExp _uuidV4Like = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);
final RegExp _slugPattern = RegExp(r'^[a-z0-9-]{1,80}$');
final RegExp _safeTextPattern = RegExp(
  r"^[0-9A-Za-zÀ-ÖØ-öø-ÿÇĞİÖŞÜçğıöşü' \-]{1,80}$",
);

bool isSafeUuid(String? value) {
  final v = value?.trim() ?? '';
  return _uuidV4Like.hasMatch(v);
}

String? sanitizeUuid(String? value) {
  final v = value?.trim() ?? '';
  return isSafeUuid(v) ? v : null;
}

String sanitizeSlug(String? value) {
  final v = (value ?? '').trim().toLowerCase();
  return _slugPattern.hasMatch(v) ? v : '';
}

String sanitizeFreeText(String? value, {int maxLen = 80}) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return '';
  final clipped = v.length > maxLen ? v.substring(0, maxLen) : v;
  return _safeTextPattern.hasMatch(clipped) ? clipped : '';
}

List<String> sanitizeUuidCsv(String? raw, {int maxItems = 50}) {
  final parts = (raw ?? '')
      .split(',')
      .map((e) => e.trim())
      .where(isSafeUuid)
      .toSet()
      .toList();
  if (parts.length <= maxItems) return parts;
  return parts.take(maxItems).toList();
}

String? sanitizeInternalRedirect(String? encodedRedirect) {
  final raw = encodedRedirect?.trim();
  if (raw == null || raw.isEmpty) return null;
  String decoded;
  try {
    decoded = Uri.decodeComponent(raw);
  } catch (_) {
    return null;
  }
  final uri = Uri.tryParse(decoded);
  if (uri == null) return null;
  if (uri.hasScheme || uri.hasAuthority) return null;
  if (!decoded.startsWith('/')) return null;
  if (decoded.startsWith('//')) return null;
  if (decoded.startsWith('/login')) return null;
  return decoded;
}
