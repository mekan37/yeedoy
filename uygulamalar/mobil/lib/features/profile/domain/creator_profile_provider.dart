import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/creator_profile_prefs.dart';

final creatorProfileProvider = FutureProvider.autoDispose<CreatorProfile>((
  ref,
) async {
  return CreatorProfilePrefs.load();
});

