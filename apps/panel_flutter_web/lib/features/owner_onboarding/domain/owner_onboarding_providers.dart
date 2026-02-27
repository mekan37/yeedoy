import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_provider.dart';
import '../data/owner_onboarding_repository.dart';
import 'owner_onboarding_models.dart';

final ownerOnboardingRepositoryProvider = Provider<OwnerOnboardingRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return OwnerOnboardingRepository(client);
});

final ownerOnboardingProgressProvider = FutureProvider.family<OwnerOnboardingProgress, String>(
  (ref, businessId) => ref.read(ownerOnboardingRepositoryProvider).getProgress(businessId),
);

final ownerBusinessProfileProvider = FutureProvider.family<OwnerBusinessProfile, String>(
  (ref, businessId) => ref.read(ownerOnboardingRepositoryProvider).getBusinessProfile(businessId),
);

final ownerBusinessHoursProvider = FutureProvider.family<OwnerBusinessHours?, String>(
  (ref, businessId) => ref.read(ownerOnboardingRepositoryProvider).getBusinessHours(businessId),
);

final ownerOnboardingMenuStatusProvider = FutureProvider.family<OwnerOnboardingMenuStatus, String>(
  (ref, businessId) => ref.read(ownerOnboardingRepositoryProvider).getMenuStatus(businessId),
);

final ownerOnboardingMenuPreviewProvider = FutureProvider.family<OwnerOnboardingMenuPreview?, String>(
  (ref, businessId) => ref.read(ownerOnboardingRepositoryProvider).getMenuPreview(businessId),
);

final ownerBusinessProfileScoreProvider = FutureProvider.family<OwnerBusinessProfileScore, String>(
  (ref, businessId) => ref.read(ownerOnboardingRepositoryProvider).getProfileScore(businessId),
);


