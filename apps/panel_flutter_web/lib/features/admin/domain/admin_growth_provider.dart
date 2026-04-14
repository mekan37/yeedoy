import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_analytics_repository.dart';
import 'admin_growth_models.dart';

final adminGrowthSummaryProvider = FutureProvider<AdminGrowthSummary>((ref) async {
  final repo = ref.watch(adminAnalyticsRepositoryProvider);
  final items = await repo.fetchGrowth(days: 30);
  var menuLinkOpened = 0;
  var qrScanned = 0;
  var menuShared = 0;
  var appInstallFromMenu = 0;
  for (final item in items) {
    menuLinkOpened += item.menuLinkOpened;
    qrScanned += item.qrScanned;
    menuShared += item.menuShared;
    appInstallFromMenu += item.appInstallFromMenu;
  }
  return AdminGrowthSummary(
    menuLinkOpened: menuLinkOpened,
    qrScanned: qrScanned,
    menuShared: menuShared,
    appInstallFromMenu: appInstallFromMenu,
  );
});
