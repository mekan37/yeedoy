import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';


import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/formatters.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/content/content_moderation.dart';
import '../../../core/errors/app_error_codes.dart';
import '../../../core/media/app_network_image.dart';
import '../../../core/media/media_upload_repository.dart';
import '../../../features/shared/ui/design_system.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/components/app_hero_header.dart';
import '../../../features/shared/ui/components/community_score_explainer_sheet.dart';
import '../../../features/shared/ui/components/quick_login_sheet.dart';
import '../../shared/ui/widgets/report_bottom_sheet.dart';
import '../../auth/domain/auth_providers.dart';
import '../../profile/domain/profile_progress_provider.dart';
import '../data/food_catalog_repository.dart';
import '../domain/food_catalog_models.dart';
import '../domain/food_catalog_search_controller.dart';
import '../data/offline_verify_queue.dart';
import '../data/menu_repository.dart';
import '../ui/menu_ocr_flow.dart';
import '../domain/menu_controllers.dart';
import '../domain/menu_models.dart';
import '../domain/menu_item_context_controller.dart';
import '../domain/menu_providers.dart';
import '../../price_alerts/ui/price_alert_sheet.dart';
import '../../../core/network/supabase_provider.dart';
import '../../shared/ui/share/business_share_card_sheet.dart';
import '../../discovery/data/discovery_repository.dart';

part 'sections/menu_item_detail_sections.dart';
part 'sections/menu_item_suggestion_sections.dart';
part 'sections/menu_item_core_sections.dart';

class _MenuItemVariant {
  const _MenuItemVariant({
    required this.id,
    required this.menuItemId,
    required this.label,
    required this.priceCents,
    required this.currency,
    required this.isDefault,
    required this.sortOrder,
  });

  final String id;
  final String menuItemId;
  final String label;
  final int priceCents;
  final String currency;
  final bool isDefault;
  final int sortOrder;

  factory _MenuItemVariant.fromMap(Map<String, dynamic> map) {
    return _MenuItemVariant(
      id: (map['id'] ?? '').toString(),
      menuItemId: (map['menu_item_id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      priceCents: ((map['price_cents'] as num?) ?? 0).toInt(),
      currency: (map['currency'] ?? 'TRY').toString(),
      isDefault: map['is_default'] == true,
      sortOrder: ((map['sort_order'] as num?) ?? 0).toInt(),
    );
  }
}

final _menuItemVariantsProvider =
    FutureProvider.family<List<_MenuItemVariant>, String>((
      ref,
      menuItemId,
    ) async {
      final id = menuItemId.trim();
      if (id.isEmpty) return const <_MenuItemVariant>[];
      final client = ref.watch(supabaseProvider);
      final res = await client
          .from('menu_item_variants')
          .select(
            'id,menu_item_id,label,price_cents,currency,is_default,is_available,sort_order',
          )
          .eq('menu_item_id', id)
          .eq('is_available', true)
          .order('sort_order', ascending: true);
      final variants = (res as List)
          .whereType<Map>()
          .map((row) => _MenuItemVariant.fromMap(row.cast<String, dynamic>()))
          .toList(growable: false);
      variants.sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });
      return variants;
    });

final _businessCityProvider = FutureProvider.family<String?, String>((
  ref,
  businessId,
) async {
  if (businessId.isEmpty) return null;
  try {
    final business = await ref
        .watch(discoveryRepositoryProvider)
        .fetchBusiness(businessId);
    return business.city;
  } catch (_) {
    return null;
  }
});

class MenuItemPage extends ConsumerWidget {
  const MenuItemPage({
    super.key,
    required this.businessId,
    required this.menuId,
    required this.menuItemId,
  });

  final String businessId;
  final String menuId;
  final String menuItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    if (menuId.isEmpty) {
      final contextAsync = ref.watch(menuItemContextProvider(menuItemId));
      return AppScaffold(
        appBar: AppAppBar(title: Text(t.menuItem)),
        body: contextAsync.when(
          loading: () => const _MenuItemSkeleton(),
          error: (e, _) => _MenuItemError(
            message: AppErrorMapper.message(e),
            onRetry: () => ref
                .read(menuItemContextProvider(menuItemId).notifier)
                .refresh(force: true),
          ),
          data: (ctx) {
            if (!ctx.ok || ctx.menuId.isEmpty || ctx.businessId.isEmpty) {
              return const _MenuItemNotFound();
            }
            return _MenuItemBody(
              businessId: ctx.businessId,
              menuId: ctx.menuId,
              menuItemId: menuItemId,
            );
          },
        ),
      );
    }
    return _MenuItemBody(
      businessId: businessId,
      menuId: menuId,
      menuItemId: menuItemId,
    );
  }
}

Widget _maxWidth(BuildContext context, Widget child) {
  final width = MediaQuery.of(context).size.width;
  final maxWidth = width >= 1040 ? 1040.0 : (width >= 720 ? 720.0 : width);
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

void _redirectToLogin(BuildContext context) {
  showQuickLoginSheet(context);
}

Future<void> _openSuggestionSheet(
  BuildContext context,
  String businessId,
  MenuItem item,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SuggestionSheet(businessId: businessId, item: item),
  );
}

Future<PriceSuggestionSubmissionResult?> _openPriceSuggestionSheet(
  BuildContext context,
  String menuItemId,
  String businessId,
  String menuId,
) async {
  return showModalBottomSheet<PriceSuggestionSubmissionResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PriceSuggestionSheet(
      menuItemId: menuItemId,
      businessId: businessId,
      menuId: menuId,
    ),
  );
}

Future<void> _openValueScoreSheet(
  BuildContext context,
  MenuItemValueScore score,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _ValueScoreSheet(score: score),
  );
}

Future<void> _openPriceThanksSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer(
          builder: (context, ref, _) {
            final t = AppLocalizations.of(context);
            final progressAsync = ref.watch(myProfileProgressProvider);
            return progressAsync.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => _ThanksContent(
                levelLabel: t.menuContributionLevelLabel,
                levelValue: t.menuLevel(1),
                progress: 0.2,
                scoreText: t.menuScoreUpdated,
              ),
              data: (progress) {
                final level = progress?.level ?? 1;
                final totalXp = progress?.totalXp ?? 0;
                final xpInLevel = progress?.xpInLevel ?? 0;
                final nextLevelXp = progress?.nextLevelXp ?? 100;
                return _ThanksContent(
                  levelLabel: t.menuContributionLevelLabel,
                  levelValue: t.menuLevel(level),
                  progress: (xpInLevel / nextLevelXp).clamp(0.0, 1.0),
                  scoreText: t.menuXpValue(totalXp),
                );
              },
            );
          },
        ),
      );
    },
  );
}
