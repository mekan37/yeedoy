import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_repository.dart';
import 'data/consent_provider.dart';
import 'domain/consent_state.dart';

/// KVKK onayı reddedilmiş/bilinmiyorken Firebase Analytics, Crashlytics ve
/// uygulamanın kendi AnalyticsRepository'si (Supabase'e event yazan) hiç
/// veri toplamamalı — önceden onay durumundan tamamen bağımsız
/// çalışıyorlardı (production-readiness denetimi B12). Bu provider,
/// `consentNotifierProvider` her değiştiğinde üçünü de tek noktadan
/// senkronlar.
final telemetryConsentLifecycleProvider = Provider<void>((ref) {
  void apply(ConsentState state) {
    final allowed = state.analytics == ConsentStatus.granted;
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(allowed);
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(allowed);
    ref.read(analyticsRepositoryProvider).updateConsent(allowed);
  }

  apply(ref.read(consentNotifierProvider));
  ref.listen<ConsentState>(consentNotifierProvider, (previous, next) {
    if (previous?.analytics == next.analytics) return;
    apply(next);
  });
});
