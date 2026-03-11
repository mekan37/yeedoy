import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'default_local_db_store.dart';
import 'local_db_store.dart';

final localDbStoreProvider = Provider<LocalDbStore>((ref) {
  return createDefaultLocalDbStore();
});
