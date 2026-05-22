import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../core/riverpod_uzantilari.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';
import 'masa_siparisi_modeli.dart';

final masaSiparisleriProvider =
    AsyncNotifierProvider<MasaSiparisiBildiricisi, List<MasaSiparisi>>(
  MasaSiparisiBildiricisi.new,
);

class MasaSiparisiBildiricisi extends AsyncNotifier<List<MasaSiparisi>> {
  @override
  Future<List<MasaSiparisi>> build() async {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return [];

    final supabase = ref.watch(supabaseProvider);

    // İlk yükleme
    final siparisler = await _yukle(supabase, kimlik.isletmeId);

    final bizFilter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'business_id',
      value: kimlik.isletmeId,
    );

    // Realtime stream — table_orders INSERT/UPDATE dinle
    final channel = supabase
        .channel('table_orders:${kimlik.isletmeId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'table_orders',
          filter: bizFilter,
          callback: (payload) {
            _yeniSiparisGeldi(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'table_orders',
          filter: bizFilter,
          callback: (payload) {
            _siparisDurumuGuncellendi(payload.newRecord);
          },
        )
        .subscribe();

    ref.onDispose(() => supabase.removeChannel(channel));

    return siparisler;
  }

  Future<List<MasaSiparisi>> _yukle(SupabaseClient supabase, String isletmeId) async {
    final rows = await supabase.rpc('get_pending_table_orders_v1', params: {
      'p_business_id': isletmeId,
    }) as List<dynamic>;
    return rows
        .map((r) => MasaSiparisi.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  void _yeniSiparisGeldi(Map<String, dynamic> row) {
    final siparis = MasaSiparisi.fromJson(row);
    state = AsyncData([siparis, ...?state.valueOrNull]);
    _titre();
  }

  void _siparisDurumuGuncellendi(Map<String, dynamic> row) {
    final guncellenmis = MasaSiparisi.fromJson(row);
    state = AsyncData(
      state.valueOrNull
              ?.map((s) => s.id == guncellenmis.id ? guncellenmis : s)
              .toList() ??
          [],
    );
  }

  Future<void> durumGuncelle(String siparisId, String yeniDurum) async {
    // Optimistic
    state = AsyncData(
      state.valueOrNull
              ?.map((s) => s.id == siparisId ? s.copyWith(durum: yeniDurum) : s)
              .toList() ??
          [],
    );
    try {
      final kimlik = ref.read(kimlikProvider).valueOrNull;
      if (kimlik is! KimlikGirilmis) return;
      final supabase = ref.read(supabaseProvider);
      await supabase.rpc('update_table_order_status_v1', params: {
        'p_order_id': siparisId,
        'p_status': yeniDurum,
        'p_business_id': kimlik.isletmeId,
      });
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  // P-6: Personel notu güncelle
  Future<void> personelNotuGuncelle(String siparisId, String? not) async {
    state = AsyncData(
      state.valueOrNull
              ?.map((s) => s.id == siparisId ? s.copyWith(personelNotu: not ?? '') : s)
              .toList() ??
          [],
    );
    try {
      final kimlik = ref.read(kimlikProvider).valueOrNull;
      if (kimlik is! KimlikGirilmis) return;
      final supabase = ref.read(supabaseProvider);
      await supabase.rpc('update_table_order_staff_note_v1', params: {
        'p_order_id': siparisId,
        'p_staff_note': not,
        'p_business_id': kimlik.isletmeId,
      });
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> yenile() async {
    final kimlik = ref.read(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return;
    state = const AsyncLoading();
    final supabase = ref.read(supabaseProvider);
    state = AsyncData(await _yukle(supabase, kimlik.isletmeId));
  }

  Future<void> _titre() async {
    if (await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }
}

final bekleyenSiparisSayisiProvider = Provider<int>((ref) {
  final siparisler = ref.watch(masaSiparisleriProvider).valueOrNull ?? [];
  return siparisler.where((s) => s.durum == 'pending').length;
});
