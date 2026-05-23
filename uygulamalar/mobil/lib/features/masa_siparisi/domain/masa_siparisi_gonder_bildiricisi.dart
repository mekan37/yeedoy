import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ag/supabase_saglayicisi.dart';
import 'masa_siparisi_modeli.dart';
import 'masa_siparisi_sepet_bildiricisi.dart';

/// Gönderilmiş siparişin sonucu
class SiparisGonderSonucu {
  final String? orderId;
  final String? hata;

  const SiparisGonderSonucu.basarili(this.orderId) : hata = null;
  const SiparisGonderSonucu.hatali(this.hata) : orderId = null;

  bool get basarili => orderId != null;
}

final masaSiparisiGonderProvider =
    AsyncNotifierProvider<MasaSiparisiGonderBildiricisi, SiparisGonderSonucu?>(
  MasaSiparisiGonderBildiricisi.new,
);

class MasaSiparisiGonderBildiricisi
    extends AsyncNotifier<SiparisGonderSonucu?> {
  @override
  Future<SiparisGonderSonucu?> build() async => null;

  Future<SiparisGonderSonucu> gonder({
    required String businessId,
    required String tableNo,
    required List<MasaSiparisKalemi> kalemler,
  }) async {
    state = const AsyncLoading();
    final client = ref.read(supabaseProvider);
    try {
      final items = kalemler
          .map((k) => {
                'menu_item_id': k.menuItemId,
                'quantity': k.adet,
                if (k.not != null && k.not!.isNotEmpty) 'note': k.not,
              })
          .toList();

      final res = await client.rpc(
        'submit_table_order_v1',
        params: {
          'p_business_id': businessId,
          'p_table_no': tableNo,
          'p_items': items,
        },
      );

      String? orderId;
      if (res is Map) {
        orderId = res['order_id']?.toString();
      } else if (res is String) {
        orderId = res;
      }

      final sonuc = SiparisGonderSonucu.basarili(orderId ?? 'ok');
      state = AsyncData(sonuc);
      // Sepeti temizle
      ref.read(masaSiparisiSepetProvider.notifier).temizle();
      return sonuc;
    } catch (e) {
      final sonuc = SiparisGonderSonucu.hatali(e.toString());
      state = AsyncData(sonuc);
      return sonuc;
    }
  }

  void sifirla() {
    state = const AsyncData(null);
  }
}

/// Kullanıcının bekleyen/son siparişleri
final siparislerimProvider =
    FutureProvider.autoDispose<List<MasaSiparisiOzet>>((ref) async {
  final client = ref.watch(supabaseProvider);
  if (client.auth.currentUser == null) return const [];

  final res = await client
      .from('table_orders')
      .select('id,business_id,table_no,status,created_at')
      .eq('user_id', client.auth.currentUser!.id)
      .order('created_at', ascending: false)
      .limit(20);

  return res
      .cast<Map<String, dynamic>>()
      .map(MasaSiparisiOzet.fromMap)
      .toList();
});
