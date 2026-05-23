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
  static String yasalUrl(String slug) => '$webBaseUrl/yasal/$slug';
  static String get termsUrl => yasalUrl('terms');
  static String get privacyPolicyUrl => yasalUrl('privacy');
  static String get cookiesUrl => yasalUrl('cookies');
  static String get communityGuidelinesUrl => yasalUrl('community');
  static String get businessTermsUrl => yasalUrl('business');
  static String get copyrightPolicyUrl => yasalUrl('copyright');
  static String get trustSafetyUrl => yasalUrl('trust-safety');
  static String get deleteAccountUrl => yasalUrl('delete-account');
  static String get kvkkUrl => privacyPolicyUrl;
  static String get gdprUrl => privacyPolicyUrl;
  static String get menuQrFileName => '${appSlug}_menu_qr.png';

  static String businessWebUrl(String businessId) =>
      '$webBaseUrl/isletme/$businessId';
  static String menuWebUrl(String menuId) => '$webBaseUrl/menu/$menuId';
  static String businessDeepLink(String businessId) =>
      '$deepLinkScheme://isletme/$businessId';

  static String menuDeepLink({required String menuId, String? businessId}) {
    if (businessId == null || businessId.isEmpty) {
      return '$deepLinkScheme://menu/$menuId';
    }
    return '$deepLinkScheme://isletme/$businessId/menu/$menuId';
  }
}

