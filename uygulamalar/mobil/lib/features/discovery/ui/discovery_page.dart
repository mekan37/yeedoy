import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:yeedoy/features/discovery/domain/business_card.dart';
import 'package:yeedoy/features/discovery/domain/discovery_search_state.dart';
import 'package:yeedoy/features/favorites/domain/favorites_controller.dart';
import 'package:yeedoy/features/menus/data/food_catalog_repository.dart';
import 'package:yeedoy/features/menus/domain/food_catalog_models.dart';
import 'package:yeedoy/features/menus/ui/menu_items_tab.dart';
import 'package:yeedoy/features/menus/domain/menu_item_search_model.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/media/app_network_image.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/formatters.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/location/user_location_controller.dart';
import '../../../core/storage/category_prefs.dart';
import '../../../core/storage/offline_cache_prefs.dart';
import '../../../core/storage/search_prefs.dart';

import '../../auth/domain/auth_providers.dart';
import '../../taste_twin/domain/taste_twin_controllers.dart';
import '../../shared/ui/components/vertical_business_card.dart';
import '../../top_businesses/ui/top_businesses_strip.dart';

import '../domain/discovery_search_notifier.dart';
import '../domain/discovery_feed_composer.dart';
import '../domain/nearby_campaign.dart';
import '../domain/nearby_campaigns_provider.dart';
import '../domain/price_anomaly.dart';
import '../domain/regional_price_index.dart';
import '../data/discovery_repository.dart';
import '../domain/home_feed.dart';
import '../domain/trend_business.dart';
import '../../../features/shared/ui/components/location_picker_sheet.dart';
import '../domain/today_pick_controller.dart';
import '../../favorites/domain/favorite_status_provider.dart';
import '../../shared/ui/business_tile.dart';
import '../../shared/ui/category_chip.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/growth/ab_experiments.dart';
import '../../../core/growth/funnel_tracker.dart';
import '../../../core/perf/firebase_perf_trace.dart';
import '../../ads/data/native_ad_controller.dart';
import '../../ads/ui/native_ad_card.dart';
import '../../profile/domain/profile_progress_provider.dart';
import '../../profile/domain/profile_progress.dart';
import '../../contribute/ui/contribute_entry.dart';
import '../../business/domain/meal_card_providers_provider.dart';
import '../../shared/ui/widgets/meal_card_badge.dart';
import '../../../core/services/home_widget_service.dart';
import '../../../core/services/assistant_shortcuts_service.dart';
import 'categories_config.dart';
import 'components/category_quick_filters.dart';
import 'components/discovery_search_bar.dart';
import 'components/search_filter_sheet.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../../features/shared/ui/components/quick_login_sheet.dart';
import '../../../features/shared/ui/components/weather_hint_bar.dart';
import '../../notifications/ui/components/notifications_bell.dart';

part 'surfaces/discovery_campaigns_tab.dart';
part 'surfaces/discovery_map_page.dart';
part 'surfaces/discovery_map_surface.dart';
part 'surfaces/discovery_insight_sections.dart';
part 'parts/discovery_providers.dart';
part 'parts/discovery_recommended_tab.dart';
part 'parts/discovery_cards.dart';
part 'parts/discovery_sheets.dart';
part 'parts/discovery_widgets.dart';
part 'parts/discovery_controls.dart';

class DiscoveryPage extends ConsumerWidget {
  const DiscoveryPage({super.key, this.initialSort});

  /// Optional initial sort to apply when the page is opened via deep link.
  /// Matches [DiscoverySort] enum name, e.g. 'priceLow'.
  final String? initialSort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    if (GoRouterState.of(context).uri.queryParameters['view'] == 'map') {
      return const _DiscoveryMapPage();
    }
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _DiscoveryPillTabBar(t: t),
          Expanded(
            child: TabBarView(
              children: [
                _KeepAliveTab(child: _RecommendedTab(initialSort: initialSort)),
                _KeepAliveTab(child: _CampaignsTab()),
                _KeepAliveTab(child: MenuItemsTab()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
