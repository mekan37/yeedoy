import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sadakat_repository.dart';

export '../data/sadakat_repository.dart' show LoyaltyCard;

final myLoyaltyCardsProvider = FutureProvider.autoDispose<List<LoyaltyCard>>((ref) async {
  final repository = ref.watch(sadakatRepositoryProvider);
  return repository.getMyLoyaltyCards();
});

/// Müşterinin owner'a gösterip taratacağı QR kodunun içeriği — düz metin
/// olarak kendi user id'si (web `/sadakat` sayfasıyla aynı format,
/// `scan_loyalty_qr_v1(business_id, user_id)` bunu doğrudan bekliyor).
final myLoyaltyQrDataProvider = Provider.autoDispose<String?>((ref) {
  final repository = ref.watch(sadakatRepositoryProvider);
  return repository.getMyLoyaltyQrData();
});
