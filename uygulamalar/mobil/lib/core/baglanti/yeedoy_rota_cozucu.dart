import '../ayarlar/uygulama_ayarlari.dart';

String? resolveYeedoyRouteFromQr(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  Uri? uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (!uri.hasScheme) {
    uri = Uri.tryParse('https://$trimmed');
    if (uri == null) return null;
  }

  if (!_isYeedoyLink(uri)) return null;
  final normalized = _normalizedPathSegments(uri);

  if (normalized.length == 2 && normalized.first == 'menu') {
    final menuId = normalized[1];
    return '/menu/$menuId?src=qr';
  }
  if (normalized.length == 2 && normalized.first == 'b') {
    final businessId = normalized[1];
    return '/isletme/$businessId';
  }
  if (normalized.length == 4 &&
      normalized[0] == 'b' &&
      normalized[2] == 'menu') {
    final businessId = normalized[1];
    final menuId = normalized[3];
    return '/isletme/$businessId/menu/$menuId';
  }

  return null;
}

bool _isYeedoyLink(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme == AppConfig.deepLinkScheme.toLowerCase()) return true;
  if (scheme != 'https' && scheme != 'http') return false;

  final host = uri.host.toLowerCase();
  final configured = AppConfig.webDomain.toLowerCase();
  return host == configured ||
      host.endsWith('.$configured') ||
      host.contains('yeedoy');
}

List<String> _normalizedPathSegments(Uri uri) {
  final segments = <String>[];
  if (uri.scheme.toLowerCase() == AppConfig.deepLinkScheme.toLowerCase() &&
      uri.host.isNotEmpty) {
    segments.add(uri.host.toLowerCase());
  }
  for (final segment in uri.pathSegments) {
    final clean = segment.trim();
    if (clean.isNotEmpty) segments.add(clean.toLowerCase());
  }
  return segments;
}

