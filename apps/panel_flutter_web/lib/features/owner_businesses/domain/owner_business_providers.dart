import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/admin_impersonation_provider.dart';
import '../data/owner_business_repository.dart';
import 'owner_business_models.dart';

final ownerBusinessesProvider = FutureProvider.autoDispose<List<OwnerBusiness>>((ref) {
  final impersonation = ref.watch(adminImpersonationProvider);
  return ref
      .read(ownerBusinessRepositoryProvider)
      .listMyBusinesses(
        actorUserId: impersonation.isActive ? impersonation.userId : null,
        roleOverride: impersonation.roleOverride?.value,
      );
});

final ownerBusinessSubmissionsProvider =
    FutureProvider.autoDispose<List<BusinessSubmission>>((ref) {
  return ref.read(ownerBusinessRepositoryProvider).listMySubmissions();
});
