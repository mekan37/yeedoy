import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../core/analytics/analytics_client.dart';
import '../../../core/analytics/app_events.dart';
import '../../../core/analytics/analytics_repository.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/growth/ab_experiments.dart';
import '../../../core/growth/funnel_tracker.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/formatters.dart';
import '../../../core/perf/firebase_perf_trace.dart';
import '../../../src/ui/components/app_appbar.dart';
import '../../../src/ui/components/app_scaffold.dart';
import '../../../src/ui/components/quick_login_sheet.dart';
import '../../auth/domain/auth_providers.dart';
import '../../business/domain/business.dart';
import '../../discovery/data/discovery_repo.dart';
import '../data/menu_repository.dart';
import '../data/offline_verify_queue.dart';
import '../domain/menu_models.dart';
import '../domain/menu_providers.dart';
import 'components/verify_price_bottom_sheet.dart';
import 'menu_ocr_flow.dart';
import '../../../src/ui/design_system.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key, required this.businessId, required this.menuId});

  final String businessId;
  final String menuId;

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

final _menuBusinessProvider = FutureProvider.family<Business, String>((
  ref,
  businessId,
) {
  return ref.watch(discoveryRepoProvider).getBusiness(businessId);
});

class _MenuPageState extends ConsumerState<MenuPage>
    with WidgetsBindingObserver {
  Map<String, DateTime?> _priceAgeMap = const {};
  String _lastIdsKey = '';
  DateTime? _lastAgeFetch;
  int _requestId = 0;
  Object? _ageError;
  bool _loggedView = false;
  bool _queueSyncing = false;
  VerifyPriceCtaPlacement _verifyPriceCtaPlacement =
      VerifyPriceCtaPlacement.bottom;
  bool _loggedVerifyCtaExperiment = false;
  Trace? _menuViewLoadTrace;
  bool _menuTraceStopped = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      startFirebaseTrace('menu_view_load').then((trace) {
        if (!mounted || _menuTraceStopped) {
          return stopFirebaseTrace(trace);
        }
        _menuViewLoadTrace = trace;
      }),
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackMenuView();
      unawaited(_flushOfflineVerifyQueue(showFeedback: false));
      unawaited(_initGrowthExperiments());
    });
  }

  Future<void> _initGrowthExperiments() async {
    final experiments = await ref.read(growthExperimentsProvider.future);
    final variant = experiments.variantOf(
      GrowthExperiment.verifyPriceCtaPlacement,
    );
    if (!mounted) return;
    setState(() {
      _verifyPriceCtaPlacement = variant == 'top'
          ? VerifyPriceCtaPlacement.top
          : VerifyPriceCtaPlacement.bottom;
    });
    if (_loggedVerifyCtaExperiment) return;
    _loggedVerifyCtaExperiment = true;
    await logExperimentExposure(
      ref.read(analyticsRepositoryProvider),
      experiment: GrowthExperiment.verifyPriceCtaPlacement,
      variant: variant,
      source: 'verify_price_sheet',
    );
  }

  @override
  void dispose() {
    if (!_menuTraceStopped) {
      _menuTraceStopped = true;
      unawaited(stopFirebaseTrace(_menuViewLoadTrace));
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _trackMenuView() async {
    if (_loggedView) return;
    _loggedView = true;
    final clientId = await getAnalyticsClientId();
    if (!mounted) return;
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: 'menu_view',
          businessId: widget.businessId,
          menuId: widget.menuId,
          source: 'menu_page',
          clientId: clientId,
        );
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: AppEvents.menuOpen,
          businessId: widget.businessId,
          menuId: widget.menuId,
          source: 'menu_page',
          clientId: clientId,
        );
    await trackFunnelStepOnce(
      ref.read(analyticsRepositoryProvider),
      step: FunnelStep.menuView,
      businessId: widget.businessId,
      menuId: widget.menuId,
      source: 'menu_page',
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_flushOfflineVerifyQueue(showFeedback: false));
      _refreshMenu(businessId: widget.businessId, menuId: widget.menuId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final businessId = widget.businessId;
    final menuId = widget.menuId;
    final sectionsAsync = ref.watch(menuSectionsProvider(menuId));
    final itemsAsync = ref.watch(menuItemsProvider(menuId));
    final menusAsync = ref.watch(businessMenusProvider(businessId));
    final cacheUpdatedAtAsync = ref.watch(
      menuItemsCacheUpdatedAtProvider(menuId),
    );

    final title = menusAsync.maybeWhen(
      data: (menus) {
        return menus
            .firstWhere(
              (m) => m.id == menuId,
              orElse: () => BusinessMenu(id: menuId, title: t.menu),
            )
            .title;
      },
      orElse: () => t.menu,
    );

    return AppScaffold(
      appBar: AppAppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshMenu(businessId: businessId, menuId: menuId);
        },
        child: Builder(
          builder: (context) {
            final error = sectionsAsync.error ?? itemsAsync.error;
            if (error != null) {
              return _MenuError(
                message: AppErrorMapper.message(error),
                onRetry: () {
                  ref.invalidate(menuSectionsProvider(menuId));
                  ref.invalidate(menuItemsProvider(menuId));
                },
              );
            }

            if (sectionsAsync.isLoading || itemsAsync.isLoading) {
              return const _MenuSkeleton();
            }
            if (!_menuTraceStopped) {
              _menuTraceStopped = true;
              unawaited(stopFirebaseTrace(_menuViewLoadTrace));
              _menuViewLoadTrace = null;
            }

            final sections = sectionsAsync.value ?? const <MenuSection>[];
            final items = itemsAsync.value ?? const <MenuItem>[];
            final cacheUpdatedAt = cacheUpdatedAtAsync.asData?.value;
            final businessAsync = ref.watch(_menuBusinessProvider(businessId));
            _maybeLoadPriceAge(items);
            final latestPriceAt = _latestPriceAt(items);

            if (items.isEmpty) {
              return const _MenuEmpty();
            }

            final orderedSections = [...sections];
            orderedSections.sort((a, b) {
              final aSort = a.sortOrder ?? 9999;
              final bSort = b.sortOrder ?? 9999;
              if (aSort != bSort) return aSort.compareTo(bSort);
              return a.title.compareTo(b.title);
            });

            final itemsBySection = <String, List<MenuItem>>{};
            final unsectioned = <MenuItem>[];
            for (final item in items) {
              final key = item.sectionId;
              if (key == null || key.isEmpty) {
                unsectioned.add(item);
              } else {
                itemsBySection.putIfAbsent(key, () => []).add(item);
              }
            }

            return _maxWidth(
              context,
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  businessAsync.when(
                    loading: () => Text(
                      title,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                    ),
                    error: (_, _) => Text(
                      title,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textStrong,
                      ),
                    ),
                    data: (business) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textStrong,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t.livePrices,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.circle,
                              size: 6,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _locText(
                                  context,
                                  business.district,
                                  business.city,
                                ),
                                style: const TextStyle(
                                  color: AppColors.muted,
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
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _MenuTopStatCard(
                          value:
                              '${_menuFreshnessScore(latestPriceAt ?? DateTime.now())}%',
                          label: t.trustScore.toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MenuTopStatCard(
                          value: _fmtAuditDateLocalized(
                            context,
                            latestPriceAt ?? cacheUpdatedAt,
                          ),
                          label: t.lastAudit.toUpperCase(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _MenuCategoryTabs(sections: orderedSections),
                  const SizedBox(height: 18),
                  for (final section in orderedSections) ...[
                    if ((itemsBySection[section.id] ?? []).isNotEmpty) ...[
                      _MenuSectionHeader(
                        title: t.signatureSection(section.title),
                        count: (itemsBySection[section.id] ?? []).length,
                      ),
                      const SizedBox(height: 10),
                      for (final item in itemsBySection[section.id]!) ...[
                        _MenuItemRow(
                          t: t,
                          item: item,
                          lastPriceAt: _priceAgeMap[item.id],
                          priceAgeError: _ageError,
                          onVerifyTap: () => _openVerifyPriceSheet(item),
                          onTap: () async {
                            final updated = await context.push(
                              '/b/$businessId/menu/$menuId/item/${item.id}',
                            );
                            if (!mounted) return;
                            if (updated == true) {
                              _refreshMenu(
                                businessId: businessId,
                                menuId: menuId,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ],
                  if (sections.isEmpty) ...[
                    _MenuSectionHeader(
                      title: t.signatureSteaks,
                      count: items.length,
                    ),
                    const SizedBox(height: 10),
                    for (final item in items) ...[
                      _MenuItemRow(
                        t: t,
                        item: item,
                        lastPriceAt: _priceAgeMap[item.id],
                        priceAgeError: _ageError,
                        onVerifyTap: () => _openVerifyPriceSheet(item),
                        onTap: () async {
                          final updated = await context.push(
                            '/b/$businessId/menu/$menuId/item/${item.id}',
                          );
                          if (!mounted) return;
                          if (updated == true) {
                            _refreshMenu(
                              businessId: businessId,
                              menuId: menuId,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ] else if (unsectioned.isNotEmpty) ...[
                    _MenuSectionHeader(
                      title: t.other,
                      count: unsectioned.length,
                    ),
                    const SizedBox(height: 10),
                    for (final item in unsectioned) ...[
                      _MenuItemRow(
                        t: t,
                        item: item,
                        lastPriceAt: _priceAgeMap[item.id],
                        priceAgeError: _ageError,
                        onVerifyTap: () => _openVerifyPriceSheet(item),
                        onTap: () async {
                          final updated = await context.push(
                            '/b/$businessId/menu/$menuId/item/${item.id}',
                          );
                          if (!mounted) return;
                          if (updated == true) {
                            _refreshMenu(
                              businessId: businessId,
                              menuId: menuId,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  const SizedBox(height: 12),
                  _PriceChangeHintCard(onTap: () => _startOcr(context, items)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _maybeLoadPriceAge(List<MenuItem> items) {
    if (items.isEmpty) return;
    final ids = items.map((e) => e.id).where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return;
    final key = ids.join(',');
    final now = DateTime.now();
    final lastFetch = _lastAgeFetch;
    final cacheValid =
        lastFetch != null && now.difference(lastFetch).inMinutes < 3;
    if (key == _lastIdsKey && cacheValid) return;
    _lastIdsKey = key;
    _loadPriceAge(ids);
  }

  Future<void> _loadPriceAge(List<String> ids) async {
    final reqId = ++_requestId;
    try {
      final res = await ref
          .read(menuRepositoryProvider)
          .getMenuItemsPriceAge(ids);
      if (!mounted || reqId != _requestId) return;
      setState(() {
        _priceAgeMap = res;
        _lastAgeFetch = DateTime.now();
        _ageError = null;
      });
    } catch (e) {
      if (!mounted || reqId != _requestId) return;
      setState(() {
        _ageError = e;
      });
    }
  }

  DateTime? _latestPriceAt(List<MenuItem> items) {
    DateTime? latest;
    for (final item in items) {
      final at = _priceAgeMap[item.id];
      if (at == null) continue;
      if (latest == null || at.isAfter(latest)) {
        latest = at;
      }
    }
    return latest;
  }

  void _refreshMenu({required String businessId, required String menuId}) {
    ref.invalidate(menuSectionsProvider(menuId));
    ref.invalidate(menuItemsProvider(menuId));
    ref.invalidate(businessMenusProvider(businessId));
    setState(() {
      _lastIdsKey = '';
      _lastAgeFetch = null;
    });
  }

  Future<void> _openVerifyPriceSheet(MenuItem item) async {
    final user = ref.read(userProvider);
    if (user == null) {
      await showQuickLoginSheet(
        context,
        redirectPath: '/b/${widget.businessId}/menu/${widget.menuId}',
      );
      return;
    }
    await VerifyPriceBottomSheet.show(
      context,
      itemName: item.name,
      currentPriceLabel: _formatPriceLocalized(context, item.price),
      ctaPlacement: _verifyPriceCtaPlacement,
      onSubmit: ({required isPriceCorrect, correctedPriceCents}) async {
        try {
          if (isPriceCorrect) {
            await ref
                .read(menuRepositoryProvider)
                .voteMenuItemPrice(
                  menuItemId: item.id,
                  vote: 1,
                  businessId: widget.businessId,
                  menuId: widget.menuId,
                );
            await _trackQuickVerify(item.id, true);
          } else {
            await ref
                .read(menuRepositoryProvider)
                .voteMenuItemPrice(
                  menuItemId: item.id,
                  vote: -1,
                  businessId: widget.businessId,
                  menuId: widget.menuId,
                );
            if (correctedPriceCents != null) {
              await ref
                  .read(menuRepositoryProvider)
                  .submitMenuItemPriceSuggestion(
                    menuItemId: item.id,
                    suggestedPriceCents: correctedPriceCents,
                    currency: 'TRY',
                    note: 'menu_page_quick_verify',
                    businessId: widget.businessId,
                    menuId: widget.menuId,
                  );
            }
            await _trackQuickVerify(item.id, false);
          }
          _refreshMenu(businessId: widget.businessId, menuId: widget.menuId);
        } on OfflineQueuedException {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).weakConnectionQueueNotice,
              ),
            ),
          );
          await _trackQuickVerify(item.id, isPriceCorrect);
        }
      },
    );
  }

  Future<void> _flushOfflineVerifyQueue({required bool showFeedback}) async {
    if (_queueSyncing) return;
    _queueSyncing = true;
    try {
      final sent = await ref
          .read(menuRepositoryProvider)
          .flushOfflineVerifyQueue();
      if (!mounted || !showFeedback || sent <= 0) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).pendingVerificationsSent(sent),
          ),
        ),
      );
    } finally {
      _queueSyncing = false;
    }
  }

  Future<void> _trackQuickVerify(String menuItemId, bool isCorrect) async {
    final clientId = await getAnalyticsClientId();
    if (!mounted) return;
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: 'menu_price_quick_verify',
          businessId: widget.businessId,
          menuId: widget.menuId,
          source: 'menu_page',
          clientId: clientId,
          meta: {'menu_item_id': menuItemId, 'is_correct': isCorrect},
        );
    await ref
        .read(analyticsRepositoryProvider)
        .logEvent(
          eventName: AppEvents.verifyPriceSubmit,
          businessId: widget.businessId,
          menuId: widget.menuId,
          source: 'menu_page',
          clientId: clientId,
          meta: {'menu_item_id': menuItemId, 'is_correct': isCorrect},
        );
    await trackFunnelStepOnce(
      ref.read(analyticsRepositoryProvider),
      step: FunnelStep.contribution,
      businessId: widget.businessId,
      menuId: widget.menuId,
      source: 'menu_page',
      meta: {'type': 'verify_price'},
    );
  }

  Future<void> _startOcr(BuildContext context, List<MenuItem> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).loadMenuItemsFirst),
        ),
      );
      return;
    }
    await startMenuPriceOcrFlow(
      context: context,
      repo: ref.read(menuRepositoryProvider),
      menuItems: items,
    );
  }
}

class _MenuTopStatCard extends StatelessWidget {
  const _MenuTopStatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCategoryTabs extends StatelessWidget {
  const _MenuCategoryTabs({required this.sections});

  final List<MenuSection> sections;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final labels = sections.isEmpty
        ? <String>[t.tabSteaks, t.tabBurgers, t.tabSides, t.tabBeverages]
        : sections.map((e) => e.title).toList(growable: false);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                Padding(
                  padding: EdgeInsets.only(
                    right: i == labels.length - 1 ? 0 : 18,
                  ),
                  child: Column(
                    children: [
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontWeight: i == 0
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: i == 0 ? AppColors.primary : AppColors.muted,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 74,
                        height: i == 0 ? 3 : 1,
                        color: i == 0 ? AppColors.primary : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.5),
      ],
    );
  }
}

class _MenuSectionHeader extends StatelessWidget {
  const _MenuSectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
        ),
        Text(
          AppLocalizations.of(context).itemsCount(count),
          style: const TextStyle(color: AppColors.muted, fontSize: 16),
        ),
      ],
    );
  }
}

class _PriceChangeHintCard extends StatelessWidget {
  const _PriceChangeHintCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.spottedPriceChange,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textStrong,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 6),
            Text(
              t.spottedPriceChangeSubtitle,
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({
    required this.t,
    required this.item,
    required this.onTap,
    required this.onVerifyTap,
    required this.lastPriceAt,
    required this.priceAgeError,
  });
  final AppLocalizations t;
  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback onVerifyTap;
  final DateTime? lastPriceAt;
  final Object? priceAgeError;

  @override
  Widget build(BuildContext context) {
    final isOutdated = item.priceStatus == 'stale' || _isVeryOld(lastPriceAt);
    final isVerified = item.priceStatus == 'verified';
    final days = _daysAgo(lastPriceAt);
    final statusText = isVerified
        ? t.verifiedDaysAgo(days)
        : (isOutdated ? t.updatedDaysAgo(days) : t.verifiedDaysAgo(days));
    final statusColor = isVerified ? AppColors.success : AppColors.warning;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
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
                      fontSize: 19,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatPriceLocalized(context, item.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textStrong,
                    fontSize: 21,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isVerified
                      ? Icons.check_circle_rounded
                      : Icons.history_toggle_off_rounded,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isOutdated)
                  OutlinedButton(
                    onPressed: onVerifyTap,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 0),
                      side: const BorderSide(color: AppColors.success),
                    ),
                    child: Text(
                      t.verify,
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (priceAgeError != null && lastPriceAt == null)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.updateDateUnavailable,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.5),
          ],
        ),
      ),
    );
  }
}

class _MenuSkeleton extends StatelessWidget {
  const _MenuSkeleton();

  @override
  Widget build(BuildContext context) {
    return _maxWidth(
      context,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: const [
          AppSkeletonLine(width: 140),
          SizedBox(height: 10),
          AppSkeletonCard(),
          SizedBox(height: 10),
          AppSkeletonCard(),
          SizedBox(height: 16),
          AppSkeletonLine(width: 160),
          SizedBox(height: 10),
          AppSkeletonCard(),
          SizedBox(height: 10),
          AppSkeletonCard(),
        ],
      ),
    );
  }
}

class _MenuEmpty extends StatelessWidget {
  const _MenuEmpty();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _maxWidth(
      context,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
        children: [
          AppEmptyState(
            icon: Icons.restaurant_menu,
            title: t.menuNotAddedYet,
            description: t.menuNotAddedYetDescription,
          ),
        ],
      ),
    );
  }
}

class _MenuError extends StatelessWidget {
  const _MenuError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _maxWidth(
      context,
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
        children: [
          AppEmptyState(
            icon: Icons.warning_amber_outlined,
            title: t.weakConnection,
            description: message.isEmpty
                ? t.contentLoadFailedCheckInternet
                : message,
            ctaLabel: t.retry,
            onCta: onRetry,
          ),
        ],
      ),
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

String _formatPriceLocalized(BuildContext context, double? price) {
  if (price == null) return AppLocalizations.of(context).unknown;
  return formatCurrency(context, price, currencyCode: 'TRY');
}

String _fmtAuditDateLocalized(BuildContext context, DateTime? d) {
  if (d == null) return AppLocalizations.of(context).unknown;
  return formatShortDate(context, d);
}

bool _isVeryOld(DateTime? d) {
  if (d == null) return true;
  return DateTime.now().difference(d).inDays >= 45;
}

int _daysAgo(DateTime? d) {
  if (d == null) return 0;
  final days = DateTime.now().difference(d).inDays;
  return days < 0 ? 0 : days;
}

String _locText(BuildContext context, String? district, String? city) {
  final d = (district ?? '').trim();
  final c = (city ?? '').trim();
  if (d.isEmpty && c.isEmpty) {
    return AppLocalizations.of(context).locationNotAvailable;
  }
  if (d.isEmpty) return c;
  if (c.isEmpty) return d;
  return '$d, $c';
}

int _menuFreshnessScore(DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days <= 7) return 100;
  if (days <= 30) return 80;
  if (days <= 90) return 60;
  if (days <= 180) return 40;
  return 20;
}
