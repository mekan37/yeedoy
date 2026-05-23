import 'package:flutter/foundation.dart';

import 'yerel_db_deposu.dart';
import 'paylasilan_tercihler_yerel_db_deposu.dart';
import 'sqflite_yerel_db_deposu.dart';

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
