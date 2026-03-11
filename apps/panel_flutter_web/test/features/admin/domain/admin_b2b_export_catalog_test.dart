import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/admin/domain/admin_b2b_export_catalog.dart';

void main() {
  test('catalog has unique export kinds and filename prefixes', () {
    final kinds = adminB2bExportCatalog.map((spec) => spec.kind).toSet();
    final filenames = adminB2bExportCatalog
        .map((spec) => spec.filenamePrefix)
        .toSet();

    expect(kinds.length, adminB2bExportCatalog.length);
    expect(filenames.length, adminB2bExportCatalog.length);
  });

  test('catalog covers internal, premium, and external lanes', () {
    final lanes = adminB2bExportCatalog.map((spec) => spec.productLane).toSet();

    expect(lanes, contains(AdminB2bProductLane.internalOps));
    expect(lanes, contains(AdminB2bProductLane.premiumAnalyticsCandidate));
    expect(lanes, contains(AdminB2bProductLane.externalMarketCandidate));
  });
}
