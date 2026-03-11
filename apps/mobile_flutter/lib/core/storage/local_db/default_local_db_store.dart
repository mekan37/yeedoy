import 'package:flutter/foundation.dart';

import 'local_db_store.dart';
import 'shared_prefs_local_db_store.dart';
import 'sqflite_local_db_store.dart';

LocalDbStore? _defaultLocalDbStore;

LocalDbStore createDefaultLocalDbStore() {
  final existing = _defaultLocalDbStore;
  if (existing != null) return existing;

  final fallbackStore = SharedPrefsLocalDbStore();
  final useSqflite =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  final store = useSqflite
      ? SqfliteLocalDbStore(fallbackStore: fallbackStore)
      : fallbackStore;
  store.initialize();
  _defaultLocalDbStore = store;
  return store;
}

void resetDefaultLocalDbStoreForTesting() {
  _defaultLocalDbStore = null;
}
