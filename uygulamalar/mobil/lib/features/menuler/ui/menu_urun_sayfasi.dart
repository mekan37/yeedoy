import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';


import '../../../uygulama/tema/renkler.dart';
import '../../../core/analitik/analitik_istemcisi.dart';
import '../../../core/analitik/uygulama_olaylari.dart';
import '../../../core/analitik/analitik_deposu.dart';
import '../../../core/ceviri/uygulama_yerellesmeleri.dart';
import '../../../core/ceviri/bicimlendiriciler.dart';
import '../../../core/hatalar/uygulama_hata_esleyicisi.dart';
import '../../../core/icerik/icerik_denetimi.dart';
import '../../../core/hatalar/uygulama_hata_kodlari.dart';
import '../../../core/medya/uygulama_ag_gorseli.dart';
import '../../../core/medya/medya_yukleme_deposu.dart';
import '../../../features/shared/ui/tasarim_sistemi.dart';
import '../../../features/shared/ui/bilesenler/uygulama_ust_cubugu.dart';
import '../../../features/shared/ui/bilesenler/one_cikan_baslik.dart';
import '../../../features/shared/ui/bilesenler/topluluk_puani_aciklama_paneli.dart';
import '../../../features/shared/ui/bilesenler/hizli_giris_paneli.dart';
import '../../shared/ui/yardimci-bilesenler/rapor_paneli.dart';
import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../../profil/domain/profil_ilerleme_saglayicisi.dart';
import '../data/yemek_katalogu_deposu.dart';
import '../domain/yemek_katalogu_modelleri.dart';
import '../domain/yemek_katalogu_arama_kontrolcusu.dart';
import '../data/offline_fiyat_dogrulama_kuyrugu.dart';
import '../data/menuler_deposu.dart';
import '../ui/menu_ocr_akisi.dart';
import '../domain/menu_kontrolculeri.dart';
import '../domain/menu_modelleri.dart';
import '../domain/menu_urun_baglam_kontrolcusu.dart';
import '../domain/menu_saglayicilari.dart';
import '../../fiyat_uyarilari/ui/fiyat_uyari_paneli.dart';
import '../../../core/ag/supabase_saglayicisi.dart';
import '../../shared/ui/paylasim/isletme_paylasim_karti_paneli.dart';
import '../../kesif/data/kesif_deposu.dart';

part 'bolumler/menu_urun_detay_bolumleri.dart';
part 'bolumler/menu_urun_oneri_bolumleri.dart';
part 'bolumler/menu_urun_temel_bolumleri.dart';

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
    this.excludedAllergens = const {},
  });

  final String businessId;
  final String menuId;
  final String menuItemId;
  /// Allergens currently filtered out in the parent menu page.
  /// When non-empty and the item contains any of these, a warning banner
  /// is shown inside the detail view.
  final Set<String> excludedAllergens;

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
              excludedAllergens: excludedAllergens,
            );
          },
        ),
      );
    }
    return _MenuItemBody(
      businessId: businessId,
      menuId: menuId,
      menuItemId: menuItemId,
      excludedAllergens: excludedAllergens,
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












