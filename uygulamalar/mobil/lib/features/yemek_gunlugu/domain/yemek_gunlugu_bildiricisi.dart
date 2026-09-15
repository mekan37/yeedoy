import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/yemek_gunlugu_repository.dart';
import 'yemek_gunlugu_modeli.dart';

final yemekGunluguProvider =
    AsyncNotifierProvider.autoDispose<YemekGunluguBildiricisi, List<YemekGunluguKaydi>>(
  YemekGunluguBildiricisi.new,
);

class YemekGunluguBildiricisi
    extends AsyncNotifier<List<YemekGunluguKaydi>> {
  @override
  Future<List<YemekGunluguKaydi>> build() => _fetch();

  Future<List<YemekGunluguKaydi>> _fetch() {
    return ref.read(yemekGunluguRepositoryProvider).getMyFoodJournal();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> guncelle({
    required String visitId,
    int? amountCents,
    String? note,
    int? rating,
  }) async {
    await ref.read(yemekGunluguRepositoryProvider).updateVisitDetails(
          visitId: visitId,
          amountCents: amountCents,
          note: note,
          rating: rating,
        );
    // Update local state optimistically
    final current = state.asData?.value ?? const [];
    state = AsyncData(
      current.map((e) {
        if (e.visitId != visitId) return e;
        return e.copyWith(
          amountCents: amountCents ?? e.amountCents,
          personalNote: note ?? e.personalNote,
          personalRating: rating ?? e.personalRating,
        );
      }).toList(),
    );
  }
}
