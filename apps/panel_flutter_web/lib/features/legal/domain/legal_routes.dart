class LegalDocumentSlug {
  const LegalDocumentSlug._();

  static const terms = 'terms';
  static const privacy = 'privacy';
  static const cookies = 'cookies';
  static const community = 'community';
  static const business = 'business';
  static const copyright = 'copyright';
  static const ai = 'ai';
  static const dmca = 'dmca';
  static const dsa = 'dsa';
  static const dataSafety = 'data-safety';
  static const trustSafety = 'trust-safety';
  static const security = 'security';
  static const lawEnforcement = 'law-enforcement';
  static const deleteAccount = 'delete-account';

  static const List<String> all = <String>[
    terms,
    privacy,
    cookies,
    community,
    business,
    copyright,
    ai,
    dmca,
    dsa,
    dataSafety,
    trustSafety,
    security,
    lawEnforcement,
    deleteAccount,
  ];
}

class LegalRoutes {
  const LegalRoutes._();

  static const index = '/legal';

  static const terms = '$index/${LegalDocumentSlug.terms}';
  static const privacy = '$index/${LegalDocumentSlug.privacy}';
  static const cookies = '$index/${LegalDocumentSlug.cookies}';
  static const community = '$index/${LegalDocumentSlug.community}';
  static const business = '$index/${LegalDocumentSlug.business}';
  static const copyright = '$index/${LegalDocumentSlug.copyright}';
  static const ai = '$index/${LegalDocumentSlug.ai}';
  static const dmca = '$index/${LegalDocumentSlug.dmca}';
  static const dsa = '$index/${LegalDocumentSlug.dsa}';
  static const dataSafety = '$index/${LegalDocumentSlug.dataSafety}';
  static const trustSafety = '$index/${LegalDocumentSlug.trustSafety}';
  static const security = '$index/${LegalDocumentSlug.security}';
  static const lawEnforcement = '$index/${LegalDocumentSlug.lawEnforcement}';
  static const deleteAccount = '$index/${LegalDocumentSlug.deleteAccount}';

  static String detail(String slug) => '$index/$slug';

  static bool isLegalPath(String path) =>
      path == index || path.startsWith('$index/');
}
