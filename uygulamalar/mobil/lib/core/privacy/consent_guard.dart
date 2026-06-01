import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/consent_provider.dart';
import 'ui/consent_bottom_sheet.dart';

/// Uygulama başlarken çağrılacak KVKK onay koruyucusu.
///
/// Kullanıcı henüz hiçbir karar vermemişse onay sayfasını gösterir.
///
/// Örnek kullanım (initState veya RouteAwareWidget içinde):
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   WidgetsBinding.instance.addPostFrameCallback((_) {
///     ConsentGuard.checkAndShow(context, ref);
///   });
/// }
/// ```
class ConsentGuard {
  const ConsentGuard._();

  /// [context] geçerli bir Navigator'a sahip olmalıdır.
  static Future<void> checkAndShow(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final state = ref.read(consentNotifierProvider);
    if (!state.hasDecided) {
      await showConsentBottomSheet(context);
    }
  }
}
