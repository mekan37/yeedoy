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
  static String get legalIndexUrl => '$webBaseUrl/legal';
  static String legalUrl(String slug) => '$webBaseUrl/legal/$slug';
  static String get termsUrl => legalUrl('terms');
  static String get privacyPolicyUrl => legalUrl('privacy');
  static String get cookiesUrl => legalUrl('cookies');
  static String get communityGuidelinesUrl => legalUrl('community');
  static String get businessTermsUrl => legalUrl('business');
  static String get copyrightPolicyUrl => legalUrl('copyright');
  static String get trustSafetyUrl => legalUrl('trust-safety');
  static String get deleteAccountUrl => legalUrl('delete-account');
  static String get kvkkUrl => privacyPolicyUrl;
  static String get gdprUrl => privacyPolicyUrl;
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
