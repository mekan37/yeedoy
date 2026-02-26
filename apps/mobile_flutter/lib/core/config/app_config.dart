class AppConfig {
  const AppConfig._();

  static const appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Yeedoy',
  );
  static const appSlug = String.fromEnvironment(
    'APP_SLUG',
    defaultValue: 'yeedoy',
  );
  static const webDomain = String.fromEnvironment(
    'WEB_DOMAIN',
    defaultValue: 'yeedoy.com',
  );
  static const deepLinkScheme = String.fromEnvironment(
    'DEEPLINK_SCHEME',
    defaultValue: 'yeedoy',
  );
  static const devToolsEnabled = bool.fromEnvironment(
    'DEV_TOOLS_ENABLED',
    defaultValue: false,
  );

  static String get webBaseUrl => 'https://$webDomain';
  static String get privacyPolicyUrl => '$webBaseUrl/privacy';
  static String get kvkkUrl => '$webBaseUrl/kvkk';
  static String get gdprUrl => '$webBaseUrl/gdpr';
  static String get copyrightPolicyUrl => '$webBaseUrl/copyright';
  static String get menuQrFileName => '${appSlug}_menu_qr.png';

  static String businessWebUrl(String businessId) =>
      '$webBaseUrl/b/$businessId';
  static String menuWebUrl(String menuId) => '$webBaseUrl/menu/$menuId';
  static String businessDeepLink(String businessId) =>
      '$deepLinkScheme://b/$businessId';

  static String menuDeepLink({required String menuId, String? businessId}) {
    if (businessId == null || businessId.isEmpty) {
      return '$deepLinkScheme://menu/$menuId';
    }
    return '$deepLinkScheme://b/$businessId/menu/$menuId';
  }
}
