import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ag/supabase_saglayicisi.dart';
import '../../../core/riverpod_uzantilari.dart';
import '../../kimlik/domain/kimlik_bildiricisi.dart';
import '../../kimlik/domain/kimlik_durum.dart';
import '../../masa_siparisleri/domain/masa_siparisi_modeli.dart';

final kdsProvider =
    AsyncNotifierProvider<KdsBildiricisi, List<MasaSiparisi>>(
  KdsBildiricisi.new,
);

/// Mutfak ekranı için filtreli sipariş akışı.
/// Yalnızca 'pending' (bekliyor) ve 'seen' (hazirlaniyor) siparişleri gösterir.
/// 30 saniyede bir otomatik yenileme yapar.
class KdsBildiricisi extends AsyncNotifier<List<MasaSiparisi>> {
  Timer? _yenilemeSayaci;

  @override
  Future<List<MasaSiparisi>> build() async {
    final kimlik = ref.watch(kimlikProvider).valueOrNull;
    if (kimlik is! KimlikGirilmis) return [];

    final supabase = ref.watch(supabaseProvider);
    final siparisler = await _yukle(supabase, kimlik.isletmeId);

    // 30 saniyelik otomatik yenileme
    _yenilemeSayaci?.cancel();
    _yenilemeSayaci = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _otomatikYenile(supabase, kimlik.isletmeId),
    );
    ref.onDispose(() => _yenilemeSayaci?.cancel());

    return siparisler;
  }

  Future<List<MasaSiparisi>> _yukle(
      SupabaseClient supabase, String isletmeId) async {
    final rows = await supabase.rpc('get_pending_table_orders_v1', params: {
      'p_business_id': isletmeId,
    }) as List<dynamic>;

    return rows
        .map((r) => MasaSiparisi.fromJson(r as Map<String, dynamic>))
        .where((s) => s.durum == 'pending' || s.durum == 'seen')
        .toList();
  }

  Future<void> _otomatikYenile(
      SupabaseClient supabase, String isletmeId) async {
    try {
      final taze = await _yukle(supabase, isletmeId);
      state = AsyncData(taze);
    } catch (_) {
      // Sessizce hata yutulanır — bir sonraki 30 saniyede tekrar denenecek
    }
  }

  /// Bir siparişi "hazirlaniyor" (seen) durumuna alır.
  Future<void> siparisKabulEt(String siparisId) async {
    await _durumGuncelle(siparisId, 'seen');
  }

  /// Bir siparişi hazır olarak işaretler — KDS'den kaldırılır.
  Future<void> siparisHazir(String siparisId) async {
    // Optimistic: önce listeden çıkar
    state = AsyncData(
      state.valueOrNull?.where((s) => s.id != siparisId).toList() ?? [],
    );
    try {
      final supabase = ref.read(supabaseProvider);
      await supabase.rpc('update_table_order_status_v1', params: {
        'p_order_id': siparisId,
        'p_status': 'done',
      });
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  Future<void> _durumGuncelle(String siparisId, String yeniDurum) async {
    // Optimistic update
    state = AsyncData(
      state.valueOrNull
              ?.map((s) => s.id == siparisId ? s.copyWith(durum: yeniDurum) : s)
              .toList() ??
          [],
    );
    try {
      final supabase = ref.read(supabaseProvider);
      await supabase.rpc('update_table_order_status_v1', params: {
        'p_order_id': siparisId,
        'p_status': yeniDurum,
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
}
