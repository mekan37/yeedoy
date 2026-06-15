import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/favorite_collections_prefs.dart';

final myFavoriteCollectionsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final collections = await FavoriteCollectionsPrefs.load();
  return collections.length;
});
