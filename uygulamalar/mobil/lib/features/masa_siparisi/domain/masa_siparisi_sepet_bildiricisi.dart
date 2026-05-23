import 'package:flutter_riverpod/legacy.dart';

import 'masa_siparisi_modeli.dart';

final masaSiparisiSepetProvider =
    StateNotifierProvider<MasaSiparisiSepetBildiricisi, List<MasaSiparisKalemi>>(
  (ref) => MasaSiparisiSepetBildiricisi(),
);

class MasaSiparisiSepetBildiricisi
    extends StateNotifier<List<MasaSiparisKalemi>> {
  MasaSiparisiSepetBildiricisi() : super(const []);

  void ekle(MasaSiparisKalemi kalem) {
    final index = state.indexWhere((k) => k.menuItemId == kalem.menuItemId);
    if (index >= 0) {
      final guncellenmis = [...state];
      guncellenmis[index] = guncellenmis[index].copyWith(
        adet: guncellenmis[index].adet + 1,
      );
      state = guncellenmis;
    } else {
      state = [...state, kalem];
    }
  }

  void cikar(String menuItemId) {
    final index = state.indexWhere((k) => k.menuItemId == menuItemId);
    if (index < 0) return;
    final guncellenmis = [...state];
    if (guncellenmis[index].adet > 1) {
      guncellenmis[index] = guncellenmis[index].copyWith(
        adet: guncellenmis[index].adet - 1,
      );
      state = guncellenmis;
    } else {
      guncellenmis.removeAt(index);
      state = guncellenmis;
    }
  }

  void temizle() {
    state = const [];
  }

  int get toplamAdet => state.fold(0, (sum, k) => sum + k.adet);

  int get toplamFiyatCents =>
      state.fold(0, (sum, k) => sum + k.priceCents * k.adet);
}
