import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/depolama/uretici_profil_tercihleri.dart';

final creatorProfileProvider = FutureProvider<CreatorProfile>((ref) async {
  return CreatorProfilePrefs.load();
});

final creatorProfileControllerProvider = Provider<CreatorProfileController>(
  (ref) => CreatorProfileController(ref),
);

class CreatorProfileController {
  CreatorProfileController(this._ref);

  final Ref _ref;

  Future<void> setIsCreator(bool value) async {
    final current = await CreatorProfilePrefs.load();
    final next = current.copyWith(isCreator: value);
    await CreatorProfilePrefs.save(next);
    _ref.invalidate(creatorProfileProvider);
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    bool? adDisclosureRequired,
  }) async {
    final current = await CreatorProfilePrefs.load();
    final next = current.copyWith(
      displayName: displayName,
      bio: bio,
      adDisclosureRequired: adDisclosureRequired,
    );
    await CreatorProfilePrefs.save(next);
    _ref.invalidate(creatorProfileProvider);
  }
}
