import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_performance/firebase_performance.dart';

import '../../../uygulama/tema/renkler.dart';
import '../../../core/analitik/analitik_istemcisi.dart';
import '../../../core/analitik/analitik_deposu.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/ceviri/bicimlendiriciler.dart';
import '../../../core/izleme/uygulama_telemetrisi.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../core/performans/firebase_performans_izi.dart';
import '../../../core/medya/uygulama_ag_gorseli.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import '../../../features/shared/ui/bilesenler/topluluk_puani_aciklama_paneli.dart';
import '../domain/isletme_detay_kontrolcusu.dart';
import '../../../features/shared/ui/bilesenler/uygulama_ust_cubugu.dart';
import '../../../features/shared/ui/bilesenler/hizli_giris_paneli.dart';
import '../../../features/shared/ui/bilesenler/hava_durumu_ipucu_cubugu.dart';
import '../../shared/ui/yardimci-bilesenler/rapor_paneli.dart';
import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../../kesif/data/kesif_deposu.dart';
import '../../favoriler/domain/favori_durumu_saglayicisi.dart';
import '../../favoriler/domain/favoriler_kontrolcu.dart';
import '../../menuler/data/menuler_deposu.dart';
import '../../menuler/domain/menu_modelleri.dart';
import '../../menuler/domain/menu_saglayicilari.dart';
import '../../ayricaliklar/domain/ayricalik_saglayicilari.dart';
import '../domain/isletme.dart';
import '../domain/isletme_ozellikleri_saglayicisi.dart';
import '../domain/ogun_karti_saglayicilari_saglayicisi.dart';
import '../domain/isletme_yoklamalari_saglayicisi.dart';
import '../domain/checkin_kontrolcusu.dart';
import '../domain/isletme_yeni_urunler_saglayicisi.dart';
import '../domain/isletme_trend_saglayicisi.dart';
import '../domain/kalabalik_kontrolcusu.dart';
import '../domain/isletme_varlik_saglayicisi.dart';
import '../ui/bilesenler/isletme_ozet_basligi.dart';
import '../../shared/ui/yardimci-bilesenler/ogun_karti_rozet.dart';
import '../../katki/ui/katki_girdisi.dart';
import '../../shared/ui/paylasim/isletme_paylasim_karti_paneli.dart';
import '../../yorumlar/domain/yorumlar_saglayicilari.dart';
import '../../sadakat/domain/sadakat_saglayicisi.dart';
import '../../masa_siparisi/ui/masa_siparisi_sayfasi.dart';

part 'bolumler/isletme_detay_bolumleri.dart';
part 'parcalar/isletme_modelleri.dart';
part 'parcalar/isletme_bolum_kaydi.dart';
part 'parcalar/isletme_basligi.dart';
part 'parcalar/isletme_menu_onizleme.dart';
part 'parcalar/isletme_durum_gorunumleri.dart';

final _businessProvider = FutureProvider.family<Business, String>((ref, id) {
  return ref.watch(discoveryRepositoryProvider).fetchBusiness(id);
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

final _businessFrequentTagsProvider =
    FutureProvider.family<List<({String tag, int count})>, String>((
      ref,
      businessId,
    ) async {
      final client = ref.watch(supabaseProvider);
      final res = await client.rpc(
        'get_business_frequent_tags_v1',
        params: {'p_business_id': businessId, 'p_limit': 8},
      );
      final rows = (res as List?) ?? const [];
      return rows
          .whereType<Map>()
          .map((row) {
            final m = row.cast<String, dynamic>();
            return (
              tag: (m['tag'] ?? '').toString(),
              count: (m['mention_count'] as num?)?.toInt() ?? 0,
            );
          })
          .where((e) => e.tag.isNotEmpty)
          .toList(growable: false);
    });

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
      startFirebaseTrace('isletme_sayfasi_yukleme').then((trace) {
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
      floatingActionButton: ContributeFab(businessId: widget.businessId),
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
            ref
                .read(discoveryRepositoryProvider)
                .invalidateBusiness(widget.businessId);
            ref.read(menuRepositoryProvider).clearReadCache();
            ref.invalidate(_businessProvider(widget.businessId));
            ref.invalidate(_businessHoursProvider(widget.businessId));
            ref.invalidate(businessMenusProvider(widget.businessId));
            ref.invalidate(businessCrowdProvider(widget.businessId));
            ref.invalidate(businessDetailProvider(widget.businessId));
            ref.invalidate(businessPerksProvider(widget.businessId));
            ref.invalidate(businessTrendingItemsProvider(widget.businessId));
            ref.invalidate(businessNewItemsProvider(widget.businessId));
            ref.invalidate(businessAmenitiesProvider(widget.businessId));
            ref.invalidate(businessMealCardProvidersProvider(widget.businessId));
            ref.invalidate(businessRecentCheckinsProvider(widget.businessId));
          },
          child: _BusinessSectionsScroll(business: business),
        ),
      ),
    );
  }
}

















