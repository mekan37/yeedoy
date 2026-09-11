import '../config/app_config.dart';
import '../security/route_sanitizer.dart';

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
    final menuId = sanitizeUuid(normalized[1]);
    if (menuId == null) return null;
    return '/menu/$menuId?src=qr';
  }
  if (normalized.length == 2 && normalized.first == 'b') {
    final businessId = sanitizeUuid(normalized[1]);
    if (businessId == null) return null;
    return '/b/$businessId';
  }
  if (normalized.length == 4 &&
      normalized[0] == 'b' &&
      normalized[2] == 'menu') {
    final businessId = sanitizeUuid(normalized[1]);
    final menuId = sanitizeUuid(normalized[3]);
    if (businessId == null || menuId == null) return null;
    return '/b/$businessId/menu/$menuId';
  }

  return null;
}

bool _isYeedoyLink(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme == AppConfig.deepLinkScheme.toLowerCase()) return true;
  if (scheme != 'https' && scheme != 'http') return false;

  // Önceden `host.contains('yeedoy')` de kabul ediliyordu — bu,
  // "yeedoy-guvenlik-dogrulama.example" veya "yeedoy.evil.com" gibi
  // üçüncü taraf alan adlarının da geçerli sayılmasına yol açıyordu.
  // Yalnızca yapılandırılmış gerçek domain (veya alt alan adı) kabul edilir.
  final host = uri.host.toLowerCase();
  final configured = AppConfig.webDomain.toLowerCase();
  return host == configured || host.endsWith('.$configured');
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
