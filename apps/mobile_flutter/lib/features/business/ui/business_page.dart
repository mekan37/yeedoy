import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_performance/firebase_performance.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/formatters.dart';
import '../../../core/monitoring/app_telemetry.dart';
import '../../../core/network/supabase_provider.dart';
import '../../../core/perf/firebase_perf_trace.dart';
import '../../../core/media/app_network_image.dart';
import '../../../features/shared/ui/design_system.dart';
import '../domain/business_detail_controller.dart';
import '../../../features/shared/ui/components/app_appbar.dart';
import '../../../features/shared/ui/components/app_scaffold.dart';
import '../../../features/shared/ui/components/quick_login_sheet.dart';
import '../../../features/shared/ui/components/weather_hint_bar.dart';
import '../../shared/ui/widgets/report_bottom_sheet.dart';
import '../../auth/domain/auth_providers.dart';
import '../../discovery/data/discovery_repository.dart';
import '../../favorites/domain/favorite_status_provider.dart';
import '../../favorites/domain/favorites_controller.dart';
import '../../menus/domain/menu_models.dart';
import '../../menus/domain/menu_providers.dart';
import '../../perks/domain/perk_providers.dart';
import '../domain/business.dart';
import '../domain/business_amenities_provider.dart';
import '../domain/business_checkins_provider.dart';
import '../domain/business_new_items_provider.dart';
import '../domain/business_trending_provider.dart';
import '../domain/crowd_controller.dart';
import '../ui/components/business_header_compact.dart';

final _businessProvider = FutureProvider.family<Business, String>((ref, id) {
  return ref.watch(discoveryRepositoryProvider).getBusiness(id);
});

final _businessHoursProvider =
    FutureProvider.family<({String? open, String? close})?, String>((
      ref,
      id,
    ) async {
      final client = ref.watch(supabaseProvider);
      final res = await client
          .from('business_hours')
          .select(
            'mon_open,mon_close,tue_open,tue_close,wed_open,wed_close,thu_open,thu_close,fri_open,fri_close,sat_open,sat_close,sun_open,sun_close',
          )
          .eq('business_id', id)
          .maybeSingle();
      if (res == null) return null;
      final map = (res as Map).cast<String, dynamic>();
      final now = DateTime.now();
      return switch (now.weekday) {
        DateTime.monday => (
          open: _timeText(map['mon_open']),
          close: _timeText(map['mon_close']),
        ),
        DateTime.tuesday => (
          open: _timeText(map['tue_open']),
          close: _timeText(map['tue_close']),
        ),
        DateTime.wednesday => (
          open: _timeText(map['wed_open']),
          close: _timeText(map['wed_close']),
        ),
        DateTime.thursday => (
          open: _timeText(map['thu_open']),
          close: _timeText(map['thu_close']),
        ),
        DateTime.friday => (
          open: _timeText(map['fri_open']),
          close: _timeText(map['fri_close']),
        ),
        DateTime.saturday => (
          open: _timeText(map['sat_open']),
          close: _timeText(map['sat_close']),
        ),
        _ => (
          open: _timeText(map['sun_open']),
          close: _timeText(map['sun_close']),
        ),
      };
    });

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
    FutureProvider.family<Map<String, List<_MenuItemVariant>>, String>((
      ref,
      itemIdsKey,
    ) async {
      final trimmed = itemIdsKey.trim();
      if (trimmed.isEmpty) return const <String, List<_MenuItemVariant>>{};
      final ids = trimmed
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (ids.isEmpty) return const <String, List<_MenuItemVariant>>{};
      final client = ref.watch(supabaseProvider);
      final res = await client
          .from('menu_item_variants')
          .select(
            'id,menu_item_id,label,price_cents,currency,is_default,is_available,sort_order',
          )
          .inFilter('menu_item_id', ids)
          .eq('is_available', true)
          .order('sort_order', ascending: true);
      final byItem = <String, List<_MenuItemVariant>>{};
      for (final row in (res as List).whereType<Map>()) {
        final variant = _MenuItemVariant.fromMap(row.cast<String, dynamic>());
        if (variant.id.isEmpty || variant.menuItemId.isEmpty) continue;
        byItem
            .putIfAbsent(variant.menuItemId, () => <_MenuItemVariant>[])
            .add(variant);
      }
      for (final entry in byItem.entries) {
        entry.value.sort((a, b) {
          if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
          return a.sortOrder.compareTo(b.sortOrder);
        });
      }
      return byItem;
    });

class _BusinessTrustSnapshot {
  const _BusinessTrustSnapshot({
    required this.menuUpdatedAt,
    required this.menuVersion,
    required this.menuSource,
    required this.menuConfidenceScore,
    required this.lastPriceVerifiedAt,
    required this.lastPriceVerifiedPeople,
    required this.trustScore,
    required this.priceChanges3m,
  });

  final DateTime? menuUpdatedAt;
  final int menuVersion;
  final String menuSource;
  final double menuConfidenceScore;
  final DateTime? lastPriceVerifiedAt;
  final int lastPriceVerifiedPeople;
  final int trustScore;
  final List<int> priceChanges3m;
}

final _businessTrustProvider =
    FutureProvider.family<_BusinessTrustSnapshot, String>((
      ref,
      businessId,
    ) async {
      final client = ref.watch(supabaseProvider);
      final now = DateTime.now();

      DateTime? menuUpdatedAt;
      var menuVersion = 1;
      var menuSource = 'owner';
      var menuConfidence = 0.0;

      try {
        final menuRes = await client
            .from('menus')
            .select('updated_at,created_at,version,source,confidence_score')
            .eq('business_id', businessId)
            .order('updated_at', ascending: false)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (menuRes != null) {
          final map = (menuRes as Map).cast<String, dynamic>();
          menuUpdatedAt = DateTime.tryParse(
            (map['updated_at'] ?? map['created_at'] ?? '').toString(),
          );
          menuVersion = (map['version'] as num?)?.toInt() ?? 1;
          menuSource = (map['source'] ?? 'owner').toString();
          menuConfidence = (map['confidence_score'] as num?)?.toDouble() ?? 0;
        }
      } catch (_) {
        final menuFallback = await client
            .from('menus')
            .select('updated_at,created_at')
            .eq('business_id', businessId)
            .order('updated_at', ascending: false)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (menuFallback != null) {
          final map = (menuFallback as Map).cast<String, dynamic>();
          menuUpdatedAt = DateTime.tryParse(
            (map['updated_at'] ?? map['created_at'] ?? '').toString(),
          );
        }
      }

      List verifiedRows;
      try {
        verifiedRows = await client
            .from('menu_item_price_suggestions')
            .select('created_at,created_by,quality_confidence')
            .eq('business_id', businessId)
            .inFilter('status', ['approved', 'handled', 'verified'])
            .gte(
              'created_at',
              now.subtract(const Duration(days: 90)).toIso8601String(),
            )
            .order('created_at', ascending: false)
            .limit(400);
      } catch (_) {
        verifiedRows = await client
            .from('menu_item_price_suggestions')
            .select('created_at,created_by,quality_confidence,status')
            .eq('business_id', businessId)
            .gte(
              'created_at',
              now.subtract(const Duration(days: 90)).toIso8601String(),
            )
            .order('created_at', ascending: false)
            .limit(400);
      }

      final rows = verifiedRows.whereType<Map>().toList(growable: false);
      DateTime? lastVerifiedAt;
      final verifierSet = <String>{};
      var confSum = 0.0;
      var confCount = 0;
      final monthBuckets = <String, int>{};
      for (final raw in rows) {
        final map = raw.cast<String, dynamic>();
        final createdAt = DateTime.tryParse(
          (map['created_at'] ?? '').toString(),
        );
        if (createdAt == null) continue;
        lastVerifiedAt ??= createdAt;
        final createdBy = (map['created_by'] ?? '').toString();
        if (createdBy.isNotEmpty &&
            createdAt.isAfter(now.subtract(const Duration(days: 30)))) {
          verifierSet.add(createdBy);
        }
        final conf = (map['quality_confidence'] as num?)?.toDouble();
        if (conf != null) {
          confSum += conf;
          confCount += 1;
        }
        final bucket =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
        monthBuckets[bucket] = (monthBuckets[bucket] ?? 0) + 1;
      }

      final month0 = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final prev1Date = DateTime(now.year, now.month - 1, 1);
      final prev2Date = DateTime(now.year, now.month - 2, 1);
      final month1 =
          '${prev1Date.year}-${prev1Date.month.toString().padLeft(2, '0')}';
      final month2 =
          '${prev2Date.year}-${prev2Date.month.toString().padLeft(2, '0')}';
      final priceChanges3m = [
        monthBuckets[month2] ?? 0,
        monthBuckets[month1] ?? 0,
        monthBuckets[month0] ?? 0,
      ];

      final qualityScore = confCount > 0 ? (confSum / confCount) * 100 : null;
      final menuScore = menuConfidence > 0 ? menuConfidence * 100 : null;
      final trustScoreRaw = qualityScore ?? menuScore ?? 50;
      final trustScore = trustScoreRaw.clamp(0, 100).round();

      return _BusinessTrustSnapshot(
        menuUpdatedAt: menuUpdatedAt,
        menuVersion: menuVersion,
        menuSource: menuSource,
        menuConfidenceScore: menuConfidence,
        lastPriceVerifiedAt: lastVerifiedAt,
        lastPriceVerifiedPeople: verifierSet.length,
        trustScore: trustScore,
        priceChanges3m: priceChanges3m,
      );
    });

class BusinessPage extends ConsumerStatefulWidget {
  const BusinessPage({super.key, required this.businessId});
  final String businessId;

  @override
  ConsumerState<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends ConsumerState<BusinessPage> {
  ProviderSubscription<AsyncValue<Business>>? _businessSub;
  final Stopwatch _openWatch = Stopwatch();
  bool _didLogBusinessOpen = false;
  Trace? _businessLoadTrace;
  bool _businessTraceStopped = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      startFirebaseTrace('business_page_load').then((trace) {
        if (!mounted || _businessTraceStopped) {
          return stopFirebaseTrace(trace);
        }
        _businessLoadTrace = trace;
      }),
    );
    _openWatch.start();
    _businessSub = ref.listenManual<AsyncValue<Business>>(
      _businessProvider(widget.businessId),
      (_, next) {
        next.whenData((business) {
          if (!_businessTraceStopped) {
            _businessTraceStopped = true;
            unawaited(stopFirebaseTrace(_businessLoadTrace));
            _businessLoadTrace = null;
          }
          if (_didLogBusinessOpen) return;
          _didLogBusinessOpen = true;
          _openWatch.stop();
          unawaited(_trackBusinessPageView(ref: ref, businessId: business.id));
          unawaited(
            ref
                .read(appTelemetryProvider)
                .logBusinessOpenLatency(
                  elapsed: _openWatch.elapsed,
                  businessId: business.id,
                ),
          );
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    if (!_businessTraceStopped) {
      _businessTraceStopped = true;
      unawaited(stopFirebaseTrace(_businessLoadTrace));
    }
    _businessSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final businessAsync = ref.watch(_businessProvider(widget.businessId));

    return AppScaffold(
      appBar: AppAppBar(
        title: Text(t.businessLabel),
        actions: [
          businessAsync.maybeWhen(
            data: (business) => IconButton(
              tooltip: t.share,
              onPressed: () => _shareBusiness(context, business),
              icon: const Icon(Icons.share_outlined),
            ),
            orElse: SizedBox.shrink,
          ),
          IconButton(
            tooltip: t.report,
            onPressed: () => _openReportSheet(context, widget.businessId),
            icon: const Icon(Icons.flag_outlined),
          ),
        ],
      ),
      body: businessAsync.when(
        loading: () => const _BusinessLoadingView(),
        error: (error, _) => _BusinessErrorView(
          message: AppErrorMapper.message(error),
          onRetry: () => ref.invalidate(_businessProvider(widget.businessId)),
        ),
        data: (business) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_businessProvider(widget.businessId));
            ref.invalidate(_businessHoursProvider(widget.businessId));
            ref.invalidate(businessMenusProvider(widget.businessId));
            ref.invalidate(businessCrowdProvider(widget.businessId));
            ref.invalidate(businessDetailProvider(widget.businessId));
            ref.invalidate(businessPerksProvider(widget.businessId));
            ref.invalidate(businessTrendingItemsProvider(widget.businessId));
            ref.invalidate(businessNewItemsProvider(widget.businessId));
            ref.invalidate(businessAmenitiesProvider(widget.businessId));
            ref.invalidate(businessRecentCheckinsProvider(widget.businessId));
          },
          child: _BusinessSectionsScroll(business: business),
        ),
      ),
    );
  }
}

class _BusinessSectionsScroll extends ConsumerWidget {
  const _BusinessSectionsScroll({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const padding = EdgeInsets.fromLTRB(16, 12, 16, 24);
    final t = AppLocalizations.of(context);
    final trustAsync = ref.watch(_businessTrustProvider(business.id));
    final trendingAsync = ref.watch(businessTrendingItemsProvider(business.id));
    final topPriceCents = trendingAsync.maybeWhen(
      data: (items) => items.isEmpty ? null : items.first.priceCents,
      orElse: () => null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 1040
            ? 1040.0
            : (constraints.maxWidth >= 720 ? 720.0 : constraints.maxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              padding: padding,
              children: [
                _BusinessHeroTrustHeader(business: business),
                const SizedBox(height: 12),
                const WeatherHintBar(compact: true),
                const SizedBox(height: 16),
                trustAsync.when(
                  loading: () => const AppSkeletonCard(),
                  error: (error, _) => AppEmptyState(
                    icon: Icons.wifi_off_outlined,
                    title: t.trustDataUnavailable,
                    description:
                        '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
                    ctaLabel: AppLocalizations.of(context).retry,
                    onCta: () =>
                        ref.invalidate(_businessTrustProvider(business.id)),
                  ),
                  data: (trust) => Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TopStatCard(
                              title: t.trustScore,
                              value: '${trust.trustScore}',
                              subtitle: '%',
                              icon: Icons.shield_rounded,
                              circleValue: trust.trustScore / 100,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TopStatCard(
                              title: t.lastUpdated,
                              value: _relativeTimeLabel(
                                context,
                                trust.menuUpdatedAt,
                              ),
                              subtitle: '',
                              icon: Icons.history_toggle_off_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TopStatCard(
                              title: t.avgCost,
                              value: _formatPriceWithCurrency(
                                context,
                                topPriceCents,
                                '?',
                              ),
                              subtitle: '',
                              icon: Icons.payments_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _CommunityVerifiedCard(
                        usersToday: trust.lastPriceVerifiedPeople <= 0
                            ? 12
                            : trust.lastPriceVerifiedPeople,
                      ),
                      const SizedBox(height: 16),
                      _PriceHistorySection(points: trust.priceChanges3m),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _BusinessMenuPreviewSection(
                  businessId: business.id,
                  fallbackCategory: business.category,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openReportSheet(context, business.id),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(t.contributeMenuPhoto),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BusinessHeroTrustHeader extends StatelessWidget {
  const _BusinessHeroTrustHeader({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroImage(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusBadge(
                        type: StatusBadgeType.verified,
                        label: AppLocalizations.of(context).verified,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${business.category} - ${_locText(context, business.district, business.city)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    final remote =
        _normalizeImageUrl(
          business.heroImageUrl ??
              business.coverImageUrl ??
              business.imageUrl ??
              business.logoUrl,
        ) ??
        '';
    if (remote.isNotEmpty) {
      return AppNetworkImage(
        url: remote,
        fit: BoxFit.cover,
        variant: AppImageVariant.medium,
      );
    }
    return Image.asset(
      _heroImageForCategory(business.category),
      fit: BoxFit.cover,
    );
  }
}

class _TopStatCard extends StatelessWidget {
  const _TopStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.circleValue,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final double? circleValue;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (circleValue != null)
            TrustScoreIndicator(
              score: (circleValue! * 100).round(),
              size: 52,
              showLabel: false,
            )
          else
            Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 10),
          Text(
            value + subtitle,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityVerifiedCard extends StatelessWidget {
  const _CommunityVerifiedCard({required this.usersToday});

  final int usersToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).communityVerified,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(
                    context,
                  ).confirmedByUsersToday(usersToday),
                  style: const TextStyle(color: AppColors.text),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.success),
        ],
      ),
    );
  }
}

class _PriceHistorySection extends StatelessWidget {
  const _PriceHistorySection({required this.points});

  final List<int> points;

  @override
  Widget build(BuildContext context) {
    final change = _priceDeltaPercent(points);
    final isUp = change >= 0;
    final trendColor = isUp ? AppColors.danger : AppColors.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).priceHistory,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
                fontSize: 32,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${isUp ? '+' : ''}$change% ${AppLocalizations.of(context).threeMonthsShort}',
                style: TextStyle(
                  color: trendColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context).chartPlaceholderSoon,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
      ],
    );
  }
}

class _BusinessMenuPreviewSection extends ConsumerStatefulWidget {
  const _BusinessMenuPreviewSection({
    required this.businessId,
    required this.fallbackCategory,
  });

  final String businessId;
  final String fallbackCategory;

  @override
  ConsumerState<_BusinessMenuPreviewSection> createState() =>
      _BusinessMenuPreviewSectionState();
}

class _BusinessMenuPreviewSectionState
    extends ConsumerState<_BusinessMenuPreviewSection> {
  String? _selectedMenuId;
  String? _selectedSectionId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final menusAsync = ref.watch(businessMenusProvider(widget.businessId));
    if (menusAsync.isLoading) {
      return const AppSkeletonCard();
    }
    if (menusAsync.hasError) {
      return AppEmptyState(
        icon: Icons.wifi_off_outlined,
        title: t.menuDataUnavailable,
        description: AppErrorMapper.message(menusAsync.error!),
      );
    }
    final menus = menusAsync.value ?? const <BusinessMenu>[];
    if (menus.isEmpty) {
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: t.menuDataUnavailable,
        description: t.noMenuProductsYet,
      );
    }

    final validMenuIds = menus
        .map((e) => e.id)
        .where((e) => e.isNotEmpty)
        .toSet();
    if (_selectedMenuId == null || !validMenuIds.contains(_selectedMenuId)) {
      _selectedMenuId = _selectDefaultMenuId(menus);
    }
    final selectedMenuId = _selectedMenuId;
    if (selectedMenuId == null || selectedMenuId.isEmpty) {
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: t.menuDataUnavailable,
        description: t.noMenuProductsYet,
      );
    }

    final sectionsAsync = ref.watch(menuSectionsProvider(selectedMenuId));
    final itemsAsync = ref.watch(menuItemsProvider(selectedMenuId));

    if (sectionsAsync.isLoading || itemsAsync.isLoading) {
      return const AppSkeletonCard();
    }
    final error = sectionsAsync.error ?? itemsAsync.error;
    if (error != null) {
      return AppEmptyState(
        icon: Icons.wifi_off_outlined,
        title: t.menuDataUnavailable,
        description: AppErrorMapper.message(error),
      );
    }

    final sections = sectionsAsync.value ?? const <MenuSection>[];
    final allItems = itemsAsync.value ?? const <MenuItem>[];
    if (allItems.isEmpty) {
      return AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: t.menuDataUnavailable,
        description: t.noMenuProductsYet,
      );
    }
    final variantKey =
        allItems
            .map((item) => item.id.trim())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final variantsByItem = ref.watch(
      _menuItemVariantsProvider(variantKey.join(',')).select((async) {
        return async.asData?.value ?? const <String, List<_MenuItemVariant>>{};
      }),
    );

    final validSectionIds = sections.map((e) => e.id).toSet();
    final selectedId = _selectedSectionId;
    if (selectedId != null && !validSectionIds.contains(selectedId)) {
      _selectedSectionId = null;
    }

    final filteredItems = _selectedSectionId == null
        ? allItems
        : allItems
              .where((item) => (item.sectionId ?? '') == _selectedSectionId)
              .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (menus.length > 1) ...[
          _MenuSelectorChips(
            menus: menus,
            selectedMenuId: selectedMenuId,
            onChanged: (value) => setState(() {
              _selectedMenuId = value;
              _selectedSectionId = null;
            }),
          ),
          const SizedBox(height: 10),
        ],
        _MenuFilterChips(
          sections: sections,
          selectedSectionId: _selectedSectionId,
          onChanged: (value) => setState(() => _selectedSectionId = value),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.menu,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textStrong,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < filteredItems.length; i++) ...[
                _BusinessMenuItemRow(
                  item: filteredItems[i],
                  variants: variantsByItem[filteredItems[i].id] ?? const [],
                  imageAsset: _menuImageForIndex(i),
                  fallbackDescription:
                      '${widget.fallbackCategory} ${t.featuredCuisineSuffix}',
                ),
                if (i != filteredItems.length - 1) const Divider(height: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String? _selectDefaultMenuId(List<BusinessMenu> menus) {
    if (menus.isEmpty) return null;
    final now = DateTime.now();
    for (final menu in menus) {
      if (menu.id.isEmpty) continue;
      final status = menu.status.toLowerCase();
      if (status == 'archived' || status == 'passive') continue;
      final from = DateTime.tryParse(menu.activeFrom ?? '');
      final to = DateTime.tryParse(menu.activeTo ?? '');
      final windowOk =
          (from == null || !from.isAfter(now)) &&
          (to == null || !to.isBefore(now));
      if (windowOk) return menu.id;
    }
    return menus.first.id;
  }
}

class _MenuSelectorChips extends StatelessWidget {
  const _MenuSelectorChips({
    required this.menus,
    required this.selectedMenuId,
    required this.onChanged,
  });

  final List<BusinessMenu> menus;
  final String selectedMenuId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < menus.length; i++) ...[
            if (i != 0) const SizedBox(width: 8),
            _MenuFilterChip(
              label: menus[i].title,
              active: selectedMenuId == menus[i].id,
              onTap: () => onChanged(menus[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuFilterChips extends StatelessWidget {
  const _MenuFilterChips({
    required this.sections,
    required this.selectedSectionId,
    required this.onChanged,
  });

  final List<MenuSection> sections;
  final String? selectedSectionId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MenuFilterChip(
            label: t.tabAllItems,
            active: selectedSectionId == null,
            onTap: () => onChanged(null),
          ),
          for (final section in sections) ...[
            const SizedBox(width: 8),
            _MenuFilterChip(
              label: section.title,
              active: selectedSectionId == section.id,
              onTap: () => onChanged(section.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuFilterChip extends StatelessWidget {
  const _MenuFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.onPrimary : AppColors.textStrong,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BusinessMenuItemRow extends StatefulWidget {
  const _BusinessMenuItemRow({
    required this.item,
    required this.variants,
    required this.imageAsset,
    required this.fallbackDescription,
  });

  final MenuItem item;
  final List<_MenuItemVariant> variants;
  final String imageAsset;
  final String fallbackDescription;

  @override
  State<_BusinessMenuItemRow> createState() => _BusinessMenuItemRowState();
}

class _BusinessMenuItemRowState extends State<_BusinessMenuItemRow> {
  String? _selectedVariantId;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final variants = widget.variants;
    if (_selectedVariantId != null &&
        !variants.any((v) => v.id == _selectedVariantId)) {
      _selectedVariantId = null;
    }
    final selectedVariant = (_selectedVariantId == null)
        ? (variants.isEmpty
              ? null
              : variants.firstWhere(
                  (v) => v.isDefault,
                  orElse: () => variants.first,
                ))
        : variants.firstWhere(
            (v) => v.id == _selectedVariantId,
            orElse: () => variants.first,
          );

    final rawImageUrl = (item.imageUrl ?? '').trim();
    final remoteImageUrl = _resolveRemoteImageUrl(rawImageUrl);
    final dataImageBytes = _decodeDataImageBytes(rawImageUrl);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: dataImageBytes != null
              ? Image.memory(
                  dataImageBytes,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                )
              : (remoteImageUrl != null
                    ? Image.network(
                        remoteImageUrl,
                        width: 76,
                        height: 76,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 76,
                          height: 76,
                          color: AppColors.card,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : (rawImageUrl.isNotEmpty
                          ? Container(
                              width: 76,
                              height: 76,
                              color: AppColors.card,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.muted,
                              ),
                            )
                          : Image.asset(
                              widget.imageAsset,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            ))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.price == null
                        ? (selectedVariant == null
                              ? AppLocalizations.of(context).unknown
                              : formatCurrency(
                                  context,
                                  selectedVariant.priceCents / 100,
                                  currencyCode: selectedVariant.currency,
                                ))
                        : formatCurrency(
                            context,
                            selectedVariant == null
                                ? item.price!
                                : (selectedVariant.priceCents / 100),
                            currencyCode: selectedVariant?.currency ?? 'TRY',
                          ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                (item.description ?? '').trim().isEmpty
                    ? widget.fallbackDescription
                    : item.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              StatusBadge(
                type: item.priceStatus == 'verified'
                    ? StatusBadgeType.verified
                    : StatusBadgeType.pending,
                label: item.priceStatus == 'verified'
                    ? AppLocalizations.of(context).verified
                    : AppLocalizations.of(context).pending,
              ),
              if (variants.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final variant in variants)
                      ChoiceChip(
                        label: Text(variant.label),
                        selected: (selectedVariant?.id ?? '') == variant.id,
                        onSelected: (_) =>
                            setState(() => _selectedVariantId = variant.id),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class BusinessHeaderSection extends ConsumerWidget {
  const BusinessHeaderSection({super.key, required this.business});
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _BusinessIdentityCard(business: business),
        const SizedBox(height: 8),
        _BusinessHeaderCompactContainer(business: business),
      ],
    );
  }
}

class _BusinessIdentityCard extends StatelessWidget {
  const _BusinessIdentityCard({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            business.name,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${business.category} - ${_locText(context, business.district, business.city)}',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _BusinessHeaderCompactContainer extends ConsumerWidget {
  const _BusinessHeaderCompactContainer({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final (openNow, closeText) = ref.watch(
      _businessHoursProvider(business.id).select((async) {
        return async.maybeWhen(
          data: (today) {
            if (today == null) return (null, t.noTime);
            return (
              _isOpenNow(today.open, today.close, DateTime.now()),
              today.close ?? t.noTime,
            );
          },
          orElse: () => (null, t.noTime),
        );
      }),
    );
    final topItems = ref.watch(
      businessTrendingItemsProvider(business.id).select((async) {
        final items = async.asData?.value ?? const [];
        if (items.isEmpty) return const <String>[];
        return items
            .map((e) => e.itemName.trim())
            .where((e) => e.isNotEmpty)
            .take(2)
            .toList(growable: false);
      }),
    );
    final topItemPriceCents = ref.watch(
      businessTrendingItemsProvider(business.id).select((async) {
        final items = async.asData?.value;
        if (items == null || items.isEmpty) return null;
        return items.first.priceCents;
      }),
    );
    final topItemCurrency = ref.watch(
      businessTrendingItemsProvider(business.id).select((async) {
        final items = async.asData?.value;
        if (items == null || items.isEmpty) return 'TRY';
        return items.first.currency;
      }),
    );
    final firstMenuId = ref.watch(
      businessMenusProvider(business.id).select((async) {
        final menus = async.asData?.value;
        if (menus == null || menus.isEmpty) return null;
        return menus.first.id;
      }),
    );
    final lastVerifiedText = _daysAgoText(context, business.lifecycleUpdatedAt);
    final topItemsText = topItems.isEmpty ? t.unknown : topItems.join(', ');

    return BusinessHeaderCompact(
      isOpenNow: openNow,
      closingTimeText: closeText,
      averagePriceText: _formatPriceWithCurrency(
        context,
        topItemPriceCents,
        topItemCurrency,
      ),
      topItemsText: topItemsText,
      lastVerifiedText: lastVerifiedText,
      onDirectionsTap: () {
        unawaited(
          _openDirections(
            businessName: business.name,
            address: business.address,
            lat: business.lat,
            lng: business.lng,
          ),
        );
      },
      onMenuTap: () {
        if (firstMenuId == null) return;
        context.go('/b/${business.id}/menu/$firstMenuId');
      },
    );
  }
}

class BusinessActionsSection extends ConsumerWidget {
  const BusinessActionsSection({super.key, required this.business});
  final Business business;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isLoggedIn = ref.watch(userProvider.select((user) => user != null));
    final isFavorited = ref.watch(isFavoritedProvider(business.id));

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () async {
                if (!isLoggedIn) {
                  await showQuickLoginSheet(
                    context,
                    redirectPath: '/b/${business.id}',
                  );
                  return;
                }
                try {
                  await ref
                      .read(favoritesControllerProvider.notifier)
                      .toggleFavorite(business.id);
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppErrorMapper.message(error))),
                  );
                }
              },
              icon: Icon(isFavorited ? Icons.star : Icons.star_border),
              label: Text(isFavorited ? t.favoriteAdded : t.addToFavorites),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/b/${business.id}/review'),
              icon: const Icon(Icons.rate_review_outlined),
              label: Text(t.writeReview),
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessTrustSection extends ConsumerWidget {
  const BusinessTrustSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final trustAsync = ref.watch(_businessTrustProvider(businessId));
    return trustAsync.when(
      loading: () => const AppSkeletonCard(),
      error: (error, _) => AppEmptyState(
        icon: Icons.wifi_off_outlined,
        title: t.trustDataUnavailable,
        description:
            '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
        ctaLabel: AppLocalizations.of(context).retry,
        onCta: () => ref.invalidate(_businessTrustProvider(businessId)),
      ),
      data: (trust) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.freshnessAndTrust,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _TrustLine(
                icon: Icons.menu_book_outlined,
                iconColor: AppColors.success,
                label: t.menuUpdatedLabel,
                value:
                    '${t.updatedDaysAgo(_daysAgo(trust.menuUpdatedAt))} ${t.versionAndSource(trust.menuVersion, _menuSourceLabel(context, trust.menuSource))}',
              ),
              const SizedBox(height: 6),
              _TrustLine(
                icon: Icons.price_check_outlined,
                iconColor: AppColors.success,
                label: t.lastPriceVerification,
                value:
                    '${t.verifiedDaysAgo(_daysAgo(trust.lastPriceVerifiedAt))} (${trust.lastPriceVerifiedPeople} ${t.usersLabel})',
              ),
              const SizedBox(height: 6),
              _TrustLine(
                icon: Icons.shield_outlined,
                iconColor: trust.trustScore >= 75
                    ? AppColors.warning
                    : AppColors.danger,
                label: t.trustScoreLabel,
                value: '${trust.trustScore}/100',
              ),
              const SizedBox(height: 12),
              Text(
                t.last3MonthsPriceChange,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 8),
              _PriceChangeMiniChart(points: trust.priceChanges3m),
            ],
          ),
        );
      },
    );
  }
}

class BusinessHoursSection extends ConsumerWidget {
  const BusinessHoursSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final hoursAsync = ref.watch(_businessHoursProvider(businessId));
    return hoursAsync.when(
      loading: () => const AppSkeletonCard(),
      error: (_, _) => AppEmptyState(
        icon: Icons.wifi_off_outlined,
        title: t.hoursInfoUnavailable,
        description: t.connectionProblemTryAgain,
        ctaLabel: AppLocalizations.of(context).retry,
        onCta: () => ref.invalidate(_businessHoursProvider(businessId)),
      ),
      data: (today) {
        if (today == null) {
          return AppEmptyState(
            icon: Icons.schedule_outlined,
            title: t.hoursInfoMissing,
            description: t.addHoursHelp,
            ctaLabel: t.reportHoursInfo,
            onCta: () => _openReportSheet(context, businessId),
          );
        }
        final openNow = _isOpenNow(today.open, today.close, DateTime.now());
        return AppCard(
          child: Row(
            children: [
              Icon(
                openNow ? Icons.schedule : Icons.schedule_outlined,
                color: openNow ? AppColors.success : AppColors.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  openNow
                      ? '${t.openNow} - ${_hoursText(context, today.open, today.close)}'
                      : '${t.closedNow} - ${_hoursText(context, today.open, today.close)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BusinessMenusSection extends ConsumerWidget {
  const BusinessMenusSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final menusAsync = ref.watch(businessMenusProvider(businessId));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.menus,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          menusAsync.when(
            loading: () => const AppSkeletonLine(width: 140),
            error: (error, _) => AppEmptyState(
              icon: Icons.wifi_off_outlined,
              title: t.menusLoadFailed,
              description:
                  '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
              ctaLabel: AppLocalizations.of(context).retry,
              onCta: () => ref.invalidate(businessMenusProvider(businessId)),
            ),
            data: (menus) {
              if (menus.isEmpty) {
                return AppEmptyState(
                  icon: Icons.menu_book_outlined,
                  title: t.noMenu,
                  description: t.addFirstMenuHelp,
                  ctaLabel: AppLocalizations.of(context).addFirstMenuCta,
                  onCta: () => _openReportSheet(context, businessId),
                );
              }
              return Column(
                children: [
                  for (final menu in menus)
                    ListTile(
                      key: ValueKey(menu.id),
                      contentPadding: EdgeInsets.zero,
                      title: Text(menu.title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/b/$businessId/menu/${menu.id}'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class BusinessCrowdSection extends ConsumerWidget {
  const BusinessCrowdSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final crowdAsync = ref.watch(businessCrowdProvider(businessId));
    return AppCard(
      child: crowdAsync.when(
        loading: () => const AppSkeletonLine(width: 150),
        error: (error, _) => AppEmptyState(
          icon: Icons.wifi_off_outlined,
          title: t.crowdInfoUnavailable,
          description:
              '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
          ctaLabel: AppLocalizations.of(context).retry,
          onCta: () => ref.invalidate(businessCrowdProvider(businessId)),
        ),
        data: (status) => Row(
          children: [
            const Icon(Icons.groups_outlined, color: AppColors.textStrong),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.liveCrowdLabel(status.state),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BusinessReviewsSection extends ConsumerWidget {
  const BusinessReviewsSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final detailAsync = ref.watch(businessDetailProvider(businessId));
    return AppCard(
      child: detailAsync.when(
        loading: () => const AppSkeletonCard(),
        error: (error, _) => AppEmptyState(
          icon: Icons.wifi_off_outlined,
          title: t.reviewsLoadFailed,
          description:
              '${AppErrorMapper.message(error)}. ${t.connectionProblemTryAgain}',
          ctaLabel: AppLocalizations.of(context).retry,
          onCta: () => ref.invalidate(businessDetailProvider(businessId)),
        ),
        data: (detail) {
          if (detail.latestReviews.isEmpty) {
            return AppEmptyState(
              icon: Icons.reviews_outlined,
              title: t.noReviews,
              description: t.leaveFirstReviewHelp,
              ctaLabel: t.writeFirstReview,
              onCta: () => context.go('/b/$businessId/review'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.recentReviews,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${detail.latestReviews.length} ${t.reviewsCountSuffix}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              for (final review in detail.latestReviews.take(3))
                ListTile(
                  key: ValueKey(review.id),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    review.title?.trim().isEmpty == false
                        ? review.title!
                        : t.reviewFallbackTitle,
                  ),
                  subtitle: Text(
                    review.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class BusinessPerksSection extends ConsumerWidget {
  const BusinessPerksSection({super.key, required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.activeCampaigns,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _PerksSummaryLine(businessId: businessId),
          _AmenitiesSummaryLine(businessId: businessId),
          _CheckinsSummaryLine(businessId: businessId),
          _NewItemsSummaryLine(businessId: businessId),
        ],
      ),
    );
  }
}

class _PerksSummaryLine extends ConsumerWidget {
  const _PerksSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perksAsync = ref.watch(businessPerksProvider(businessId));
    return perksAsync.when(
      loading: () => const AppSkeletonLine(width: 160),
      error: (_, _) => const SizedBox.shrink(),
      data: (perks) => Text(
        perks.isEmpty
            ? AppLocalizations.of(context).noActiveCampaign
            : '${perks.length} ${AppLocalizations.of(context).activeCampaignCountLabel}',
        style: const TextStyle(color: AppColors.muted),
      ),
    );
  }
}

class _AmenitiesSummaryLine extends ConsumerWidget {
  const _AmenitiesSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amenitiesAsync = ref.watch(businessAmenitiesProvider(businessId));
    return amenitiesAsync.maybeWhen(
      data: (items) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          items.isEmpty
              ? AppLocalizations.of(context).noAmenityInfo
              : '${items.length} ${AppLocalizations.of(context).amenityCountLabel}',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _CheckinsSummaryLine extends ConsumerWidget {
  const _CheckinsSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(businessRecentCheckinsProvider(businessId));
    return checkinsAsync.maybeWhen(
      data: (count) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          count <= 0
              ? AppLocalizations.of(context).noLocationVerificationData
              : '${AppLocalizations.of(context).lastLocationVerification}: $count',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _NewItemsSummaryLine extends ConsumerWidget {
  const _NewItemsSummaryLine({required this.businessId});
  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newItemsAsync = ref.watch(businessNewItemsProvider(businessId));
    return newItemsAsync.maybeWhen(
      data: (items) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          items.isEmpty
              ? AppLocalizations.of(context).noNewProductRecord
              : '${AppLocalizations.of(context).newProduct}: ${items.length}',
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class BusinessFooterSection extends StatelessWidget {
  const BusinessFooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${AppLocalizations.of(context).reportInfoErrorPrefix} ${_fmtDate(DateTime.now())}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PriceChangeMiniChart extends StatelessWidget {
  const _PriceChangeMiniChart({required this.points});
  final List<int> points;

  @override
  Widget build(BuildContext context) {
    final values = points.length == 3 ? points : [0, 0, 0];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 54,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: maxValue <= 0
                          ? 6
                          : (8 + (values[i] / maxValue) * 42).clamp(8, 52),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${values[i]}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (i != values.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _BusinessLoadingView extends StatelessWidget {
  const _BusinessLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        AppSkeletonCard(),
        SizedBox(height: 10),
        AppSkeletonCard(),
        SizedBox(height: 10),
        AppSkeletonCard(),
      ],
    );
  }
}

class _BusinessErrorView extends StatelessWidget {
  const _BusinessErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
      children: [
        AppEmptyState(
          icon: Icons.wifi_off_outlined,
          title: AppLocalizations.of(context).weakConnection,
          description:
              '$message\n${AppLocalizations.of(context).connectionProblemTryAgain}',
          ctaLabel: AppLocalizations.of(context).retry,
          onCta: onRetry,
        ),
      ],
    );
  }
}

void _openReportSheet(BuildContext context, String businessId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ReportBottomSheet.business(
      businessId: businessId,
      redirectUrl: GoRouterState.of(context).uri.toString(),
    ),
  );
}

Future<void> _shareBusiness(BuildContext context, Business business) async {
  final t = AppLocalizations.of(context);
  final deep = AppConfig.businessDeepLink(business.id);
  final web = AppConfig.businessWebUrl(business.id);
  final msg = t.shareBusinessMessage(
    business.name,
    _locText(context, business.district, business.city),
    web,
    deep,
  );
  await SharePlus.instance.share(ShareParams(text: msg));
}

String _locText(BuildContext context, String? district, String? city) {
  final d = (district ?? '').trim();
  final c = (city ?? '').trim();
  if (d.isEmpty && c.isEmpty) return AppLocalizations.of(context).noLocation;
  if (d.isEmpty) return c;
  if (c.isEmpty) return d;
  return '$d / $c';
}

String _fmtDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

String _formatPriceWithCurrency(
  BuildContext context,
  int? cents,
  String currency,
) {
  if (cents == null || cents <= 0) return AppLocalizations.of(context).unknown;
  final normalizedCurrency = RegExp(r'^[A-Z]{3}$').hasMatch(currency)
      ? currency
      : 'TRY';
  return formatCurrency(context, cents / 100, currencyCode: normalizedCurrency);
}

String? _timeText(dynamic value) {
  if (value == null) return null;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return raw.length >= 5 ? raw.substring(0, 5) : raw;
}

bool _isOpenNow(String? open, String? close, DateTime now) {
  final o = _parseMinutes(open);
  final c = _parseMinutes(close);
  if (o == null || c == null) return false;
  final hm = now.hour * 60 + now.minute;
  if (o <= c) return hm >= o && hm <= c;
  return hm >= o || hm <= c;
}

String _hoursText(BuildContext context, String? open, String? close) {
  final o = (open ?? '').trim();
  final c = (close ?? '').trim();
  if (o.isEmpty || c.isEmpty) return AppLocalizations.of(context).noHoursInfo;
  return '$o - $c';
}

String _daysAgoText(BuildContext context, DateTime? value) {
  final t = AppLocalizations.of(context);
  if (value == null) return t.unknown;
  final diff = DateTime.now().difference(value);
  if (diff.inDays <= 0) return t.today;
  return '${diff.inDays} ${t.dayUnit}';
}

int _daysAgo(DateTime? value) {
  if (value == null) return 0;
  final diff = DateTime.now().difference(value);
  if (diff.isNegative) return 0;
  return diff.inDays;
}

int? _parseMinutes(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

String _heroImageForCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('steak') || c.contains('et')) {
    return 'assets/images/categories/kebap.png';
  }
  if (c.contains('burger')) {
    return 'assets/images/categories/burger.png';
  }
  if (c.contains('pizza')) {
    return 'assets/images/categories/pizza.png';
  }
  if (c.contains('kahvalt')) {
    return 'assets/images/categories/kahvalti.png';
  }
  return 'assets/images/categories/doner.png';
}

String _menuImageForIndex(int index) {
  const pool = [
    'assets/images/categories/kebap.png',
    'assets/images/categories/pizza.png',
    'assets/images/categories/burger.png',
    'assets/images/categories/lahmacun.png',
    'assets/images/categories/tatli.png',
  ];
  return pool[index % pool.length];
}

String? _normalizeImageUrl(String? url) {
  final value = (url ?? '').trim();
  if (value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasAuthority) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return value;
}

String? _resolveRemoteImageUrl(String? url) {
  final value = (url ?? '').trim();
  if (value.isEmpty) return null;
  if (value.startsWith('data:image/')) return null;
  final normalized = _normalizeImageUrl(value);
  if (normalized != null) {
    final uri = Uri.tryParse(normalized);
    if (uri != null &&
        uri.host.contains('google.') &&
        uri.path.contains('/imgres')) {
      final raw = uri.queryParameters['imgurl'];
      final extracted = _normalizeImageUrl(raw);
      if (extracted != null) return extracted;
    }
    return normalized;
  }
  if (value.startsWith('//')) {
    return _normalizeImageUrl('https:$value');
  }
  if (!value.contains('://') && value.contains('.')) {
    return _normalizeImageUrl('https://$value');
  }
  return null;
}

Uint8List? _decodeDataImageBytes(String? value) {
  final raw = (value ?? '').trim();
  if (!raw.startsWith('data:image/')) return null;
  final marker = ';base64,';
  final idx = raw.indexOf(marker);
  if (idx <= 0) return null;
  final payload = raw.substring(idx + marker.length);
  if (payload.isEmpty) return null;
  try {
    return base64Decode(payload);
  } catch (_) {
    return null;
  }
}

int _priceDeltaPercent(List<int> points) {
  if (points.length < 3) return 0;
  final first = points.first;
  final last = points.last;
  if (first <= 0) return last > 0 ? 5 : 0;
  final pct = ((last - first) / first) * 100;
  return pct.round();
}

String _relativeTimeLabel(BuildContext context, DateTime? value) {
  final t = AppLocalizations.of(context);
  if (value == null) return t.updatedDaysAgo(0);
  final diff = DateTime.now().difference(value);
  if (diff.inDays < 1) return t.updatedDaysAgo(0);
  if (diff.inDays < 30) return t.updatedDaysAgo(diff.inDays);
  return formatShortDate(context, value);
}

String _menuSourceLabel(BuildContext context, String source) {
  final t = AppLocalizations.of(context);
  switch (source.trim().toLowerCase()) {
    case 'owner':
      return t.sourceOwner;
    case 'community':
      return t.sourceCommunity;
    case 'ai':
      return t.sourceAi;
    default:
      return t.unknown;
  }
}

Future<void> _openDirections({
  required String businessName,
  required String? address,
  required double? lat,
  required double? lng,
}) async {
  final uri = lat != null && lng != null
      ? Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
        )
      : Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent('${businessName.trim()} ${(address ?? '').trim()}')}',
        );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> _trackBusinessPageView({
  required WidgetRef ref,
  required String businessId,
}) async {
  final clientId = await getAnalyticsClientId();
  await ref
      .read(analyticsRepositoryProvider)
      .logEvent(
        eventName: 'business_page_view',
        businessId: businessId,
        source: 'business_page',
        clientId: clientId,
      );
}
