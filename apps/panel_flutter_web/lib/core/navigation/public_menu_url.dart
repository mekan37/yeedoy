import 'package:flutter_dotenv/flutter_dotenv.dart';

const _fallbackWebNextBase = 'http://localhost:3000';
const _defaultMenuLang = 'tr';
const _defaultBrandTheme = 'bold';

String _resolveLang(String lang) {
  return lang.trim().toLowerCase().startsWith('en') ? 'en' : _defaultMenuLang;
}

String _resolveTheme(String theme) {
  switch (theme.trim().toLowerCase()) {
    case 'minimal':
    case 'elegant':
    case 'bold':
      return theme.trim().toLowerCase();
    default:
      return _defaultBrandTheme;
  }
}

String buildPublicMenuUrl({
  required String businessId,
  String? businessSlug,
  String? businessPublicSlug,
  String lang = _defaultMenuLang,
  String theme = _defaultBrandTheme,
}) {
  final key = _resolvePublicMenuKey(
    businessId: businessId,
    businessSlug: businessSlug,
    businessPublicSlug: businessPublicSlug,
  );
  final safeKey = Uri.encodeComponent(key);
  final base = _resolveWebNextBaseUri();
  return base
      .replace(
        path: '/m/$safeKey',
        queryParameters: {
          'lang': _resolveLang(lang),
          'theme': _resolveTheme(theme),
        },
      )
      .toString();
}

String _resolvePublicMenuKey({
  required String businessId,
  String? businessSlug,
  String? businessPublicSlug,
}) {
  final publicSlug = _normalizePublicMenuKey(businessPublicSlug);
  if (publicSlug != null) return publicSlug;
  final slug = _normalizePublicMenuKey(businessSlug);
  if (slug != null) return slug;
  return businessId.trim();
}

String? _normalizePublicMenuKey(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) return null;
  return normalized;
}

String buildQrMenuUrl({
  required String businessId,
  String lang = _defaultMenuLang,
  String theme = _defaultBrandTheme,
}) {
  final key = businessId.trim();
  final safeKey = Uri.encodeComponent(key);
  final base = _resolveWebNextBaseUri();
  return base
      .replace(
        path: '/qr/$safeKey',
        queryParameters: {
          'lang': _resolveLang(lang),
          'theme': _resolveTheme(theme),
        },
      )
      .toString();
}

String buildQrLoginUrl({
  required String businessId,
  String lang = _defaultMenuLang,
  String theme = _defaultBrandTheme,
}) {
  final base = _resolveWebNextBaseUri();
  final redirect =
      '/qr/${Uri.encodeComponent(businessId.trim())}'
      '?lang=${Uri.encodeQueryComponent(_resolveLang(lang))}'
      '&theme=${Uri.encodeQueryComponent(_resolveTheme(theme))}';
  return base
      .replace(path: '/login', queryParameters: {'redirect': redirect})
      .toString();
}

String buildPanelSessionHandoffUrl() {
  final base = _resolveWebNextBaseUri();
  return base
      .replace(path: '/auth/panel-handoff', query: null, fragment: null)
      .toString();
}

Uri _resolveWebNextBaseUri() {
  final raw = (dotenv.env['BASE_URL_WEB_NEXT'] ?? '').trim();
  final parsed = Uri.tryParse(raw);
  if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
    return parsed.replace(path: '', query: null, fragment: null);
  }
  return Uri.parse(_fallbackWebNextBase);
}
