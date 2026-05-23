import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:url_launcher/url_launcher.dart';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/analitik/analitik_istemcisi.dart';
import '../../../core/analitik/uygulama_olaylari.dart';
import '../../../core/analitik/analitik_deposu.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/buyume/ab_deneyleri.dart';
import '../../../core/buyume/huni_izleyici.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/ceviri/bicimlendiriciler.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../core/performans/firebase_performans_izi.dart';
import '../../../features/shared/ui/bilesenler/uygulama_ust_cubugu.dart';
import '../../../features/shared/ui/bilesenler/topluluk_puani_aciklama_paneli.dart';
import '../../../features/shared/ui/bilesenler/hizli_giris_paneli.dart';
import '../../../features/shared/ui/bilesenler/hava_durumu_ipucu_cubugu.dart';
import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../../isletme/domain/isletme.dart';
import '../../kesif/data/kesif_deposu.dart';
import '../../../core/depolama/cevrimdisi_onbellek_tercihleri.dart';
import '../data/menuler_deposu.dart';
import '../data/offline_fiyat_dogrulama_kuyrugu.dart';
import '../domain/menu_modelleri.dart';
import '../domain/menu_saglayicilari.dart';
import 'bilesenler/fiyat_dogrulama_paneli.dart';
import 'menu_ocr_akisi.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';

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
  return ref.watch(discoveryRepositoryProvider).fetchBusiness(businessId);
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

class _MenuPageState extends ConsumerState<MenuPage>
    with WidgetsBindingObserver {
  Map<String, DateTime?> _priceAgeMap = const {};
  String _lastIdsKey = '';
  DateTime? _lastAgeFetch;
  int _requestId = 0;
  Object? _ageError;
  bool _loggedView = false;
  bool _queueSyncing = false;
  bool _savingOffline = false;
  VerifyPriceCtaPlacement _verifyPriceCtaPlacement =
      VerifyPriceCtaPlacement.bottom;
  bool _loggedVerifyCtaExperiment = false;
  Trace? _menuViewLoadTrace;
  bool _menuTraceStopped = false;
  final _scrollCtrl = ScrollController();
  final _sectionKeys = <String, GlobalKey>{};
  Set<String> _excludedAllergens = const {};

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
    _scrollCtrl.dispose();
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

  static const _knownAllergens = [
    ('gluten',      'Gluten'),
    ('dairy',       'Süt / Laktoz'),
    ('eggs',        'Yumurta'),
    ('peanuts',     'Yer Fıstığı'),
    ('tree_nuts',   'Ağaç Kuruyemişi'),
    ('fish',        'Balık'),
    ('shellfish',   'Kabuklu Deniz Ürünleri'),
    ('soy',         'Soya'),
    ('sesame',      'Susam'),
    ('celery',      'Kereviz'),
    ('mustard',     'Hardal'),
    ('lupin',       'Acı Bakla'),
    ('molluscs',    'Yumuşakçalar'),
    ('sulphites',   'Sülfitler'),
  ];

  Future<void> _showAllergenFilterSheet(BuildContext context) async {
    // Work on a copy to support cancel
    var current = Set<String>.from(_excludedAllergens);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alerjen Filtresi',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Seçili alerjenleri içeren öğeler gizlenir.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: _knownAllergens.map((a) {
                      return CheckboxListTile(
                        title: Text(a.$2),
                        value: current.contains(a.$1),
                        dense: true,
                        onChanged: (v) {
                          setSheetState(() {
                            if (v == true) {
                              current = {...current, a.$1};
                            } else {
                              current = current.where((x) => x != a.$1).toSet();
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setSheetState(() => current = {});
                      },
                      child: const Text('Temizle'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() => _excludedAllergens = current);
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        current.isEmpty ? 'Uygula' : '${current.length} filtre uygula',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSectionJumpSheet(
      BuildContext context, List<MenuSection> sections) async {
    final t = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.localeName.startsWith('tr') ? 'Bölüme Atla' : 'Jump to section',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sections.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final section = sections[index];
                  return ListTile(
                    title: Text(section.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.muted),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      final key = _sectionKeys[section.id];
                      if (key?.currentContext != null) {
                        Scrollable.ensureVisible(
                          key!.currentContext!,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          alignment: 0.0,
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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

    final menuScheduleLabel = menusAsync.maybeWhen(
      data: (menus) {
        final m = menus.firstWhere(
          (m) => m.id == menuId,
          orElse: () => BusinessMenu(id: menuId, title: ''),
        );
        final parts = <String>[];
        if ((m.kind ?? '').isNotEmpty) parts.add(m.kind!);
        if ((m.activeFrom ?? '').isNotEmpty && (m.activeTo ?? '').isNotEmpty) {
          final fromDt = DateTime.tryParse(m.activeFrom!);
          final toDt = DateTime.tryParse(m.activeTo!);
          if (fromDt != null && toDt != null) {
            String hm(DateTime d) =>
                '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
            parts.add('${hm(fromDt)}-${hm(toDt)}');
          }
        }
        return parts.isEmpty ? null : parts.join(' • ');
      },
      orElse: () => null,
    );

    final offlineSaved = ref
        .watch(menuOfflineSavedProvider(menuId))
        .asData
        ?.value ?? false;

    final sections = sectionsAsync.value ?? const <MenuSection>[];

    return AppScaffold(
      appBar: AppAppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: t.localeName.startsWith('tr')
                ? 'Alerjen Filtresi'
                : 'Allergen filter',
            onPressed: () => _showAllergenFilterSheet(context),
            icon: Badge(
              isLabelVisible: _excludedAllergens.isNotEmpty,
              backgroundColor: AppColors.warning,
              label: Text('${_excludedAllergens.length}'),
              child: const Icon(Icons.no_food_outlined),
            ),
          ),
          if (sections.isNotEmpty)
            IconButton(
              tooltip: t.localeName.startsWith('tr')
                  ? 'Bölüme Atla'
                  : 'Jump to section',
              onPressed: () => _showSectionJumpSheet(context, sections),
              icon: const Icon(Icons.list_rounded),
            ),
          if (_savingOffline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: t.localeName.startsWith('tr')
                  ? (offlineSaved ? 'Çevrimdışı kaydedildi' : 'Çevrimdışı kaydet')
                  : (offlineSaved ? 'Saved offline' : 'Save for offline'),
              onPressed: _saveForOffline,
              icon: Icon(
                offlineSaved
                    ? Icons.offline_pin_outlined
                    : Icons.download_outlined,
                color: offlineSaved ? AppColors.success : null,
              ),
            ),
        ],
      ),
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
            final allItems = itemsAsync.value ?? const <MenuItem>[];
            // Apply allergen filter
            final items = _excludedAllergens.isEmpty
                ? allItems
                : allItems.where((item) {
                    final allergens = item.allergens;
                    return !_excludedAllergens
                        .any((a) => allergens.contains(a));
                  }).toList();
            final variantKeyList =
                items
                    .map((item) => item.id.trim())
                    .where((id) => id.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
            final variantsByItem = ref.watch(
              _menuItemVariantsProvider(variantKeyList.join(',')).select((
                async,
              ) {
                return async.asData?.value ??
                    const <String, List<_MenuItemVariant>>{};
              }),
            );
            final cacheUpdatedAt = cacheUpdatedAtAsync.asData?.value;
            final businessAsync = ref.watch(_menuBusinessProvider(businessId));
            _maybeLoadPriceAge(items);
            final latestPriceAt = _latestPriceAt(items);

            // Dış menü / foto / QR kontrolü — native olmayan kind'larda items boş olur
            final currentMenu = menusAsync.asData?.value.cast<BusinessMenu?>()
                .firstWhere((m) => m?.id == menuId, orElse: () => null);
            if (currentMenu != null && !currentMenu.isNative) {
              return _ExternalMenuView(menu: currentMenu);
            }

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
                controller: _scrollCtrl,
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
                        const SizedBox(height: 10),
                        const WeatherHintBar(compact: true),
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
                          label: t.communityScoreMenuFreshnessLabel.toUpperCase(),
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
                  const SizedBox(height: 12),
                  const CommunityScoreGuideCard(
                    kind: CommunityScoreKind.dataTrust,
                    margin: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),
                  if (menuScheduleLabel != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            menuScheduleLabel,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MenuCategoryTabs(sections: orderedSections),
                  if (_excludedAllergens.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.no_food_outlined,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_excludedAllergens.length} alerjen filtresi aktif — bazı öğeler gizlendi',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(
                                () => _excludedAllergens = const {}),
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  for (final section in orderedSections) ...[
                    if ((itemsBySection[section.id] ?? []).isNotEmpty) ...[
                      _MenuSectionHeader(
                        key: _sectionKeys.putIfAbsent(
                            section.id, () => GlobalKey()),
                        title: t.signatureSection(section.title),
                        count: (itemsBySection[section.id] ?? []).length,
                      ),
                      const SizedBox(height: 10),
                      for (final item in itemsBySection[section.id]!) ...[
                        _MenuItemRow(
                          t: t,
                          item: item,
                          variants: variantsByItem[item.id] ?? const [],
                          lastPriceAt: _priceAgeMap[item.id],
                          priceAgeError: _ageError,
                          onVerifyTap: () => _openVerifyPriceSheet(item),
                          onTap: () async {
                            final updated = await context.push(
                              '/isletme/$businessId/menu/$menuId/item/${item.id}',
                              extra: _excludedAllergens,
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
                        variants: variantsByItem[item.id] ?? const [],
                        lastPriceAt: _priceAgeMap[item.id],
                        priceAgeError: _ageError,
                        onVerifyTap: () => _openVerifyPriceSheet(item),
                        onTap: () async {
                          final updated = await context.push(
                            '/isletme/$businessId/menu/$menuId/item/${item.id}',
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
                        variants: variantsByItem[item.id] ?? const [],
                        lastPriceAt: _priceAgeMap[item.id],
                        priceAgeError: _ageError,
                        onVerifyTap: () => _openVerifyPriceSheet(item),
                        onTap: () async {
                          final updated = await context.push(
                            '/isletme/$businessId/menu/$menuId/item/${item.id}',
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
          .fetchMenuItemsPriceAge(ids);
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

  Future<void> _saveForOffline() async {
    if (_savingOffline) return;
    setState(() => _savingOffline = true);
    try {
      ref.invalidate(menuSectionsProvider(widget.menuId));
      ref.invalidate(menuItemsProvider(widget.menuId));
      ref.invalidate(businessMenusProvider(widget.businessId));
      // Wait for providers to finish fetching (they will re-save to cache)
      await Future.wait([
        ref.read(menuSectionsProvider(widget.menuId).future).catchError((_) => <MenuSection>[]),
        ref.read(menuItemsProvider(widget.menuId).future).catchError((_) => <MenuItem>[]),
      ]);
      await OfflineCachePrefs.markMenuSavedForOffline(widget.menuId);
      ref.invalidate(menuOfflineSavedProvider(widget.menuId));
      if (!mounted) return;
      final t = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.localeName.startsWith('tr')
                ? 'Menü çevrimdışı için kaydedildi'
                : 'Menu saved for offline use',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      // no-op — cache may be stale but not a blocker
    } finally {
      if (mounted) setState(() => _savingOffline = false);
    }
  }

  Future<void> _openVerifyPriceSheet(MenuItem item) async {
    final user = ref.read(userProvider);
    if (user == null) {
      await showQuickLoginSheet(
        context,
        redirectPath: '/isletme/${widget.businessId}/menu/${widget.menuId}',
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
  const _MenuSectionHeader({super.key, required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: title,
      trailing: Text(
        AppLocalizations.of(context).itemsCount(count),
        style: const TextStyle(color: AppColors.muted, fontSize: 16),
      ),
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
            AppBadge(label: t.livePrices, tone: AppBadgeTone.success),
            const SizedBox(height: 10),
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

class _MenuItemRow extends StatefulWidget {
  const _MenuItemRow({
    required this.t,
    required this.item,
    required this.variants,
    required this.onTap,
    required this.onVerifyTap,
    required this.lastPriceAt,
    required this.priceAgeError,
  });
  final AppLocalizations t;
  final MenuItem item;
  final List<_MenuItemVariant> variants;
  final VoidCallback onTap;
  final VoidCallback onVerifyTap;
  final DateTime? lastPriceAt;
  final Object? priceAgeError;

  @override
  State<_MenuItemRow> createState() => _MenuItemRowState();
}

class _MenuItemRowState extends State<_MenuItemRow> {
  String? _selectedVariantId;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final item = widget.item;
    final variants = widget.variants;
    final lastPriceAt = widget.lastPriceAt;
    final priceAgeError = widget.priceAgeError;
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
    final isOutdated = item.priceStatus == 'stale' || _isVeryOld(lastPriceAt);
    final isVerified = item.priceStatus == 'verified';
    final imageUrl = _resolveRemoteImageUrl(item.imageUrl);
    final dataBytes = _decodeDataImageBytes(item.imageUrl);
    final days = _daysAgo(lastPriceAt);
    final statusText = isVerified
        ? t.verifiedDaysAgo(days)
        : (isOutdated ? t.updatedDaysAgo(days) : t.verifiedDaysAgo(days));
    final statusColor = isVerified ? AppColors.success : AppColors.warning;
    final selectedPrice = selectedVariant == null
        ? item.price
        : selectedVariant.priceCents / 100;
    final selectedCurrency = selectedVariant?.currency ?? 'TRY';
    final isUnavailable = !item.isAvailable;
    return Opacity(
      opacity: isUnavailable ? 0.5 : 1.0,
      child: InkWell(
      onTap: isUnavailable ? null : widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null || dataBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: dataBytes != null
                        ? Image.memory(
                            dataBytes,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            imageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            semanticLabel: item.name,
                            errorBuilder: (_, _, _) => Container(
                              width: 56,
                              height: 56,
                              color: AppColors.card,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textStrong,
                          fontSize: 19,
                        ),
                      ),
                      if (isUnavailable)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.muted.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Tükendi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatPriceLocalized(
                    context,
                    selectedPrice,
                    currencyCode: selectedCurrency,
                  ),
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
                    onPressed: widget.onVerifyTap,
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
            if (variants.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
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
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.5),
          ],
        ),
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

String _formatPriceLocalized(
  BuildContext context,
  double? price, {
  String currencyCode = 'TRY',
}) {
  if (price == null) {
    return AppLocalizations.of(context).localeName.startsWith('tr')
        ? 'Fiyata sorunuz'
        : 'Price on request';
  }
  return formatCurrency(context, price, currencyCode: currencyCode);
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

// ── Dış menü görünümü (external / photo / qr) ────────────────────────────────

class _ExternalMenuView extends StatelessWidget {
  const _ExternalMenuView({required this.menu});
  final BusinessMenu menu;

  @override
  Widget build(BuildContext context) {
    final isTr = AppLocalizations.of(context).localeName.startsWith('tr');

    return _maxWidth(
      context,
      ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        children: [
          // Menü fotoğrafı veya QR resmi varsa göster
          if ((menu.sourceImageUrl ?? '').isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                menu.sourceImageUrl!,
                fit: BoxFit.contain,
                semanticLabel: 'Menü görseli',
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // İkon + başlık
          Icon(
            menu.isQr
                ? Icons.qr_code_2_rounded
                : menu.isPhoto
                    ? Icons.photo_library_outlined
                    : Icons.open_in_new_rounded,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            menu.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textStrong,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isTr
                ? 'Bu menü dış bir platformda barındırılmaktadır.'
                : 'This menu is hosted on an external platform.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 15),
          ),

          // Dış link varsa aç butonu
          if ((menu.externalUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(menu.externalUrl!);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(isTr ? 'Menüyü Aç' : 'Open Menu'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // URL önizleme
            Text(
              menu.externalUrl!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}











