class LegalRouteEntry {
  const LegalRouteEntry({
    required this.label,
    required this.slug,
  });

  final String label;
  final String slug;
}

class LegalRoutes {
  const LegalRoutes._();

  static const hub = '/legal';

  static const termsSlug = 'terms';
  static const privacySlug = 'privacy';
  static const cookiesSlug = 'cookies';
  static const communitySlug = 'community';
  static const businessSlug = 'business';
  static const copyrightSlug = 'copyright';
  static const aiSlug = 'ai';
  static const dmcaSlug = 'dmca';
  static const dsaSlug = 'dsa';
  static const dataSafetySlug = 'data-safety';
  static const trustSafetySlug = 'trust-safety';
  static const securitySlug = 'security';
  static const lawEnforcementSlug = 'law-enforcement';
  static const deleteAccountSlug = 'delete-account';

  static String detail(String slug) => '$hub/$slug';

  static bool matches(String path) =>
      path == hub || path.startsWith('$hub/');

  static const footerLinks = <LegalRouteEntry>[
    LegalRouteEntry(label: 'Kullanım Şartları', slug: termsSlug),
    LegalRouteEntry(label: 'Gizlilik Politikası', slug: privacySlug),
    LegalRouteEntry(label: 'Çerez Politikası', slug: cookiesSlug),
    LegalRouteEntry(label: 'Topluluk Kuralları', slug: communitySlug),
    LegalRouteEntry(label: 'DMCA', slug: dmcaSlug),
    LegalRouteEntry(label: 'Trust & Safety', slug: trustSafetySlug),
    LegalRouteEntry(label: 'Hesap Silme', slug: deleteAccountSlug),
  ];

  static const productLinks = <LegalRouteEntry>[
    LegalRouteEntry(label: 'İşletme Koşulları', slug: businessSlug),
    LegalRouteEntry(label: 'Yapay Zeka / OCR', slug: aiSlug),
    LegalRouteEntry(label: 'Veri Güvenliği', slug: dataSafetySlug),
    LegalRouteEntry(label: 'Güvenlik Politikası', slug: securitySlug),
  ];
}
