import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kimlik/domain/kimlik_saglayicilari.dart';
import '../data/profil_deposu.dart';
import 'gunluk_mikro_gorev.dart';

final myDailyMicroTaskProvider = FutureProvider<DailyMicroTask?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).fetchMyDailyMicroTask();
});


