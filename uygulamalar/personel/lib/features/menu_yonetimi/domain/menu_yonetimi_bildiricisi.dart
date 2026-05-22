import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../core/riverpod_uzantilari.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';
import 'menu_kalemi_modeli.dart';

final menuYonetimiProvider =
    AsyncNotifierProvider<MenuYonetimiBildiricisi, List<MenuKalemi>>(
      MenuYonetimiBildiricisi.new,
    );

class MenuYonetimiBildiricisi extends AsyncNotifier<List<MenuKalemi>> {
  @override
  Future<List<MenuKalemi>> build() async {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return [];

    final supabase = ref.read(supabaseProvider);
    final kalemler = await _yukle(supabase, kimlik.isletmeId);

    final menuFilter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'business_id',
      value: kimlik.isletmeId,
    );

    final channel = supabase
        .channel('menu_items:${kimlik.isletmeId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'menu_items',
          filter: menuFilter,
          callback: (payload) => _kalemGuncellendi(payload.newRecord),
        )
        .subscribe();

    ref.onDispose(() => supabase.removeChannel(channel));

    return kalemler;
  }

  void _kalemGuncellendi(Map<String, dynamic> row) {
    final mevcut = state.valueOrNull;
    MenuKalemi? onceki;
    for (final kalem in mevcut ?? const <MenuKalemi>[]) {
      if (kalem.id == row['id']) {
        onceki = kalem;
        break;
      }
    }
    final guncellenmis = MenuKalemi.fromJson(
      row,
    ).copyWith(kategori: onceki?.kategori);
    state = AsyncData(
      mevcut?.map((k) => k.id == guncellenmis.id ? guncellenmis : k).toList() ??
          [],
    );
  }

  Future<List<MenuKalemi>> _yukle(
    SupabaseClient supabase,
    String isletmeId,
  ) async {
    final rows =
        await supabase
                .from('menu_items')
                .select(
                  'id, name, section_id, price_cents, is_available, is_today_special, stock_count, sort_order, image_url, menu_sections(title, sort_order)',
                )
                .eq('business_id', isletmeId)
                .order('sort_order', ascending: true)
                .order('name', ascending: true)
            as List<dynamic>;

    return rows
        .map((r) => MenuKalemi.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> mevcutToggle(String kalemId, bool yeniDeger) async {
    // Optimistic
    state = AsyncData(
      state.valueOrNull
              ?.map((k) => k.id == kalemId ? k.copyWith(mevcut: yeniDeger) : k)
              .toList() ??
          [],
    );
    try {
      await ref
          .read(supabaseProvider)
          .from('menu_items')
          .update({'is_available': yeniDeger})
          .eq('id', kalemId);
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> spesiyelToggle(String kalemId, bool yeniDeger) async {
    // Optimistic
    state = AsyncData(
      state.valueOrNull
              ?.map(
                (k) => k.id == kalemId
                    ? k.copyWith(bugunSpesiyel: yeniDeger)
                    : k.copyWith(bugunSpesiyel: false),
              )
              .toList() ??
          [],
    );
    try {
      final supabase = ref.read(supabaseProvider);
      final kimlik = ref.read(kimlikProvider).valueOrNull;
      if (kimlik is! KimlikGirilmis) return;
      await supabase.rpc(
        'set_today_special_v1',
        params: {
          'p_business_id': kimlik.isletmeId,
          'p_item_id': yeniDeger ? kalemId : null,
        },
      );
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> fiyatGuncelle(String kalemId, double yeniFiyat) async {
    state = AsyncData(
      state.valueOrNull
              ?.map((k) => k.id == kalemId ? k.copyWith(fiyat: yeniFiyat) : k)
              .toList() ??
          [],
    );
    try {
      await ref
          .read(supabaseProvider)
          .from('menu_items')
          .update({
            'price_cents': (yeniFiyat * 100).round(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', kalemId);
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> topluGuncelle(bool yeniDeger) async {
    final kalemler = state.valueOrNull ?? [];
    state = AsyncData(
      kalemler.map((k) => k.copyWith(mevcut: yeniDeger)).toList(),
    );
    try {
      final kimlik = ref.read(kimlikProvider).valueOrNull;
      if (kimlik is! KimlikGirilmis) return;
      await ref
          .read(supabaseProvider)
          .from('menu_items')
          .update({
            'is_available': yeniDeger,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('business_id', kimlik.isletmeId);
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> stokGuncelle(String kalemId, int yeniStok) async {
    state = AsyncData(
      state.valueOrNull
              ?.map(
                (k) => k.id == kalemId ? k.copyWith(stokSayisi: yeniStok) : k,
              )
              .toList() ??
          [],
    );
    try {
      await ref
          .read(supabaseProvider)
          .from('menu_items')
          .update({
            'stock_count': yeniStok,
            'is_available': yeniStok > 0,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', kalemId);
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  // P-10: Görsel URL güncelle
  Future<void> gorselGuncelle(String kalemId, String? url) async {
    state = AsyncData(
      state.valueOrNull
              ?.map((k) => k.id == kalemId ? k.copyWith(gorselUrl: url) : k)
              .toList() ??
          [],
    );
    try {
      await ref
          .read(supabaseProvider)
          .from('menu_items')
          .update({
            'image_url': url,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', kalemId);
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> yenile() async {
    final kimlik = ref.read(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return;
    state = const AsyncLoading();
    state = AsyncData(
      await _yukle(ref.read(supabaseProvider), kimlik.isletmeId),
    );
  }
}
