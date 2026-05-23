import 'dart:collection';

import '../../core/ayarlar/uygulama_ayarlari.dart';
import 'yasal_modeller.dart';

class LegalLinkDescriptor {
  const LegalLinkDescriptor({
    required this.slug,
    required this.title,
    required this.description,
    required this.url,
    this.policyType,
  });

  final String slug;
  final String title;
  final String description;
  final String url;
  final String? policyType;
}

class LegalCatalog {
  const LegalCatalog._();

  static final List<LegalLinkDescriptor> requiredAcceptanceLinks =
      List<LegalLinkDescriptor>.unmodifiable(<LegalLinkDescriptor>[
        LegalLinkDescriptor(
          slug: LegalPolicyType.terms,
          policyType: LegalPolicyType.terms,
          title: 'Kullanım Şartları',
          description: 'Hesap, hizmet sınırları ve içerik sorumluluğu.',
          url: AppConfig.termsUrl,
        ),
        LegalLinkDescriptor(
          slug: LegalPolicyType.privacy,
          policyType: LegalPolicyType.privacy,
          title: 'Gizlilik Politikası',
          description: 'Kişisel veri işleme, saklama ve hak süreçleri.',
          url: AppConfig.privacyPolicyUrl,
        ),
      ]);

  static final cookies = LegalLinkDescriptor(
    slug: LegalPolicyType.cookies,
    title: 'Çerez Politikası',
    description: 'Web çerezleri ve tercih yönetimi.',
    url: AppConfig.cookiesUrl,
  );

  static final List<LegalLinkDescriptor> trustLinks =
      List<LegalLinkDescriptor>.unmodifiable(<LegalLinkDescriptor>[
        LegalLinkDescriptor(
          slug: LegalPolicyType.community,
          title: 'Topluluk Kuralları',
          description: 'Kötüye kullanım, taciz ve spam kuralları.',
          url: AppConfig.communityGuidelinesUrl,
        ),
        LegalLinkDescriptor(
          slug: LegalPolicyType.trustSafety,
          title: 'Trust & Safety',
          description: 'Moderasyon, risk yönetimi ve abuse önleme yaklaşımı.',
          url: AppConfig.trustSafetyUrl,
        ),
        LegalLinkDescriptor(
          slug: LegalPolicyType.copyright,
          title: 'Telif Politikası',
          description: 'DMCA ve telif bildirim süreçleri.',
          url: AppConfig.copyrightPolicyUrl,
        ),
      ]);

  static final List<LegalLinkDescriptor> settingsLinks =
      List<LegalLinkDescriptor>.unmodifiable(<LegalLinkDescriptor>[
        ...requiredAcceptanceLinks,
        LegalLinkDescriptor(
          slug: LegalPolicyType.community,
          title: 'Topluluk Kuralları',
          description: 'Topluluk güveni ve davranış kuralları.',
          url: AppConfig.communityGuidelinesUrl,
        ),
        LegalLinkDescriptor(
          slug: LegalPolicyType.deleteAccount,
          title: 'Hesap Silme Politikası',
          description: 'Silme, dışa aktarma ve gizlilik başvurusu süreçleri.',
          url: AppConfig.deleteAccountUrl,
        ),
      ]);

  static final Map<String, LegalLinkDescriptor> _byPolicyType =
      UnmodifiableMapView<String, LegalLinkDescriptor>(
        <String, LegalLinkDescriptor>{
          for (final item in <LegalLinkDescriptor>[
            ...requiredAcceptanceLinks,
            cookies,
            ...trustLinks,
            ...settingsLinks,
          ])
            if (item.policyType != null) item.policyType!: item,
        },
      );

  static final Map<String, LegalLinkDescriptor> _bySlug =
      UnmodifiableMapView<String, LegalLinkDescriptor>(
        <String, LegalLinkDescriptor>{
          for (final item in <LegalLinkDescriptor>[
            ...requiredAcceptanceLinks,
            cookies,
            ...trustLinks,
            ...settingsLinks,
          ])
            item.slug: item,
        },
      );

  static LegalLinkDescriptor? byPolicyType(String policyType) =>
      _byPolicyType[policyType];

  static LegalLinkDescriptor? bySlug(String slug) => _bySlug[slug];

  static String displayTitleForPolicyType(String policyType) =>
      byPolicyType(policyType)?.title ?? policyType;
}

