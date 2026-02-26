import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/app_role_providers.dart';

final adminAccessProvider = FutureProvider<bool>((ref) async {
  return ref.watch(canAccessAdminPanelProvider.future);
});
