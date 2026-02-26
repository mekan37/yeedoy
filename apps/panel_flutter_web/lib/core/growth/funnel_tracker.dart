import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/analytics_client.dart';
import '../analytics/analytics_repository.dart';

enum FunnelStep { open, locationSet, firstBusiness, menuView, contribution }

const _funnelStepToEvent = <FunnelStep, String>{
  FunnelStep.open: 'funnel_open',
  FunnelStep.locationSet: 'funnel_location_set',
  FunnelStep.firstBusiness: 'funnel_first_business',
  FunnelStep.menuView: 'funnel_menu_view',
  FunnelStep.contribution: 'funnel_contribution',
};

String _prefKey(FunnelStep step) => 'funnel_done_${step.name}';

Future<bool> trackFunnelStepOnce(
  AnalyticsRepository analytics, {
  required FunnelStep step,
  String? businessId,
  String? menuId,
  String? source,
  Map<String, dynamic>? meta,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final key = _prefKey(step);
  if (prefs.getBool(key) == true) {
    return false;
  }
  final eventName = _funnelStepToEvent[step];
  if (eventName == null) return false;
  final clientId = await getAnalyticsClientId();
  final ok = await analytics.logEvent(
    eventName: eventName,
    businessId: businessId,
    menuId: menuId,
    source: source,
    clientId: clientId,
    meta: meta,
  );
  if (ok) {
    await prefs.setBool(key, true);
  }
  return ok;
}
