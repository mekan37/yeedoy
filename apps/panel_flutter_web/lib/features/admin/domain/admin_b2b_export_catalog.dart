enum AdminB2bExportKind {
  anonymousTrends,
  regionalPriceIndex,
  menuInflation,
  priceAnomalies,
}

enum AdminB2bProductLane {
  internalOps,
  premiumAnalyticsCandidate,
  externalMarketCandidate,
}

enum AdminB2bPrivacyClass {
  anonymousAggregate,
  restrictedAggregate,
  contractOnly,
}

enum AdminB2bFreshness {
  dailySeries,
  rollingWindow,
}

enum AdminB2bExportStatus {
  internalReady,
  premiumCandidate,
  externalCandidate,
}

class AdminB2bExportSpec {
  const AdminB2bExportSpec({
    required this.kind,
    required this.filenamePrefix,
    required this.productLane,
    required this.privacyClass,
    required this.freshness,
    required this.status,
  });

  final AdminB2bExportKind kind;
  final String filenamePrefix;
  final AdminB2bProductLane productLane;
  final AdminB2bPrivacyClass privacyClass;
  final AdminB2bFreshness freshness;
  final AdminB2bExportStatus status;
}

const adminB2bExportCatalog = <AdminB2bExportSpec>[
  AdminB2bExportSpec(
    kind: AdminB2bExportKind.anonymousTrends,
    filenamePrefix: 'b2b_anonymous_trends',
    productLane: AdminB2bProductLane.externalMarketCandidate,
    privacyClass: AdminB2bPrivacyClass.anonymousAggregate,
    freshness: AdminB2bFreshness.dailySeries,
    status: AdminB2bExportStatus.externalCandidate,
  ),
  AdminB2bExportSpec(
    kind: AdminB2bExportKind.regionalPriceIndex,
    filenamePrefix: 'b2b_regional_price_index',
    productLane: AdminB2bProductLane.externalMarketCandidate,
    privacyClass: AdminB2bPrivacyClass.anonymousAggregate,
    freshness: AdminB2bFreshness.rollingWindow,
    status: AdminB2bExportStatus.externalCandidate,
  ),
  AdminB2bExportSpec(
    kind: AdminB2bExportKind.menuInflation,
    filenamePrefix: 'b2b_menu_inflation',
    productLane: AdminB2bProductLane.premiumAnalyticsCandidate,
    privacyClass: AdminB2bPrivacyClass.restrictedAggregate,
    freshness: AdminB2bFreshness.rollingWindow,
    status: AdminB2bExportStatus.premiumCandidate,
  ),
  AdminB2bExportSpec(
    kind: AdminB2bExportKind.priceAnomalies,
    filenamePrefix: 'b2b_price_anomalies',
    productLane: AdminB2bProductLane.internalOps,
    privacyClass: AdminB2bPrivacyClass.contractOnly,
    freshness: AdminB2bFreshness.rollingWindow,
    status: AdminB2bExportStatus.internalReady,
  ),
];
