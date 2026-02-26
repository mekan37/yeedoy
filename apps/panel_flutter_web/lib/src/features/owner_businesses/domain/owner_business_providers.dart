import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_business_repository.dart';
import 'owner_business_models.dart';

final ownerBusinessesProvider = FutureProvider.autoDispose<List<OwnerBusiness>>((ref) {
  return ref.read(ownerBusinessRepositoryProvider).listMyBusinesses();
});

final ownerBusinessSubmissionsProvider =
    FutureProvider.autoDispose<List<BusinessSubmission>>((ref) {
  return ref.read(ownerBusinessRepositoryProvider).listMySubmissions();
});
