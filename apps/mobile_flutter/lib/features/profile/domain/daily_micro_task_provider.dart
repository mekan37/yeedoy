import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_providers.dart';
import '../data/profile_repository.dart';
import 'daily_micro_task.dart';

final myDailyMicroTaskProvider = FutureProvider<DailyMicroTask?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;
  return ref.read(profileRepositoryProvider).fetchMyDailyMicroTask();
});
