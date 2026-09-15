import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/group_requests_repository.dart';
import 'group_request_models.dart';

/// Kullanıcının grup taleplerinin listesi — hem liste sayfası (MyGroupRequestsPage)
/// hem detay sayfası (GroupRequestDetailPage) paylaşıyor. Detay sayfasındaki bir
/// durum değişikliği (kapatma/teklif kabul etme) bu provider'ı invalidate etmezse
/// liste sayfasına dönüldüğünde eski durum görünmeye devam ediyordu — B41.
final myRequestsProvider = FutureProvider<List<GroupRequest>>((ref) async {
  return ref.read(groupRequestsRepositoryProvider).listMyRequests();
});
