import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_mobile/mobile_app.dart';
import 'core/monitoring/app_telemetry.dart';
import 'core/monitoring/error_taxonomy.dart';
import 'core/perf/perf_slo.dart';
import 'core/security/secure_local_storage.dart';
import 'core/security/safe_debug_print.dart';
import 'firebase_options.dart';

final firebaseAnalytics = FirebaseAnalytics.instance;
void _installFrameDropObserver(ProviderContainer container) {
  if (!kProfileMode) return;
  var sampled = 0;
  var janky = 0;
  var severe = 0;
  WidgetsBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      sampled += 1;
      final totalMs = t.totalSpan.inMicroseconds / 1000.0;
      if (totalMs > 16.67) janky += 1;
      if (totalMs > 50.0) severe += 1;
    }
    if (sampled >= 120) {
      if (kDebugMode) {
        debugPrint(
          'frame_stats profile: sampled=$sampled janky=$janky severe=$severe',
        );
      }
      unawaited(
        container
            .read(appTelemetryProvider)
            .logFrameWindow(
              sampledFrames: sampled,
              jankyFrames: janky,
              severeFrames: severe,
            ),
      );
      sampled = 0;
      janky = 0;
      severe = 0;
    }
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

Future<void> main() async {
  final startupWatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  installSafeDebugPrint();
  // Run Firebase and MobileAds initialization in parallel — they are independent.
  // A failure here (missing/invalid config, platform quirk) must not crash
  // app startup: Firebase-dependent features simply stay disabled and the
  // failure is logged for Crashlytics/observability follow-up instead.
  var firebaseReady = false;
  try {
    await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      MobileAds.instance.initialize(),
    ]);
    firebaseReady = true;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (error, stack) {
    debugPrint(
      'Firebase/MobileAds initialization failed — continuing without it: $error\n$stack',
    );
  }

  await dotenv.load(fileName: ".env");

  final supabaseUrl = _requireEnv('SUPABASE_URL');
  final supabaseAnonKey = _requireEnv('SUPABASE_ANON_KEY');
  final supabaseHost = Uri.parse(supabaseUrl).host.split('.').first;
  final localStorage = SecureLocalStorage(
    persistSessionKey: 'sb-$supabaseHost-auth-token',
  );
  bool hasPersistedSession = false;
  try {
    hasPersistedSession = await localStorage.hasAccessToken();
  } catch (_) {
    hasPersistedSession = false;
  }
  final startupType = hasPersistedSession ? StartupType.warm : StartupType.cold;
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(localStorage: localStorage),
  );

  final rootContainer = ProviderContainer();
  _installFrameDropObserver(rootContainer);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    final taxonomy = classifyError(details.exception);
    if (firebaseReady) {
      FirebaseCrashlytics.instance.setCustomKey('error_taxonomy', taxonomy.name);
      FirebaseCrashlytics.instance.setCustomKey('error_source', 'flutter_error');
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
    unawaited(
      rootContainer
          .read(appTelemetryProvider)
          .reportError(
            details.exception,
            details.stack ?? StackTrace.current,
            source: 'flutter_error',
          ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final taxonomy = classifyError(error);
    if (firebaseReady) {
      FirebaseCrashlytics.instance.setCustomKey('error_taxonomy', taxonomy.name);
      FirebaseCrashlytics.instance.setCustomKey('error_source', 'platform_dispatcher');
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    unawaited(
      rootContainer
          .read(appTelemetryProvider)
          .reportError(error, stack, source: 'platform_dispatcher'),
    );
    return true;
  };

  WidgetsBinding.instance.addPostFrameCallback((_) {
    startupWatch.stop();
    unawaited(
      rootContainer
          .read(appTelemetryProvider)
          .logStartup(startupWatch.elapsed, type: startupType),
    );
  });

  runApp(
    UncontrolledProviderScope(
      container: rootContainer,
      child: const MobileApp(),
    ),
  );
}

String _requireEnv(String key) {
  final value = dotenv.env[key]?.trim();
  if (value == null || value.isEmpty) {
    throw StateError('Missing required environment variable: $key');
  }
  return value;
}
