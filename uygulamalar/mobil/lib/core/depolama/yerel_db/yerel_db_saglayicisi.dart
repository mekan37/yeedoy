import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'varsayilan_yerel_db_deposu.dart';
import 'yerel_db_deposu.dart';

final localDbStoreProvider = Provider<LocalDbStore>((ref) {
  return createDefaultLocalDbStore();
});
