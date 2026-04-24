import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrapWebApp(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final supabaseUrl = _requireEnv('SUPABASE_URL');
  final supabaseAnonKey = _requireEnv('SUPABASE_ANON_KEY');
  final sentryDsn = dotenv.env['SENTRY_DSN']?.trim() ?? '';

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = kReleaseMode ? 'production' : 'staging';
        // Sample 20% of transactions; errors always captured.
        options.tracesSampleRate = 0.2;
        // Strip PII: no email, IP, or username in events.
        options.beforeSend = (event, hint) {
          return event.copyWith(
            user: event.user?.copyWith(
              email: null,
              ipAddress: null,
              username: null,
            ),
          );
        };
      },
      appRunner: () => runApp(ProviderScope(child: app)),
    );
  } else {
    runApp(ProviderScope(child: app));
  }
}

String _requireEnv(String key) {
  final value = dotenv.env[key]?.trim();
  if (value == null || value.isEmpty) {
    throw StateError('Missing required environment variable: $key');
  }
  return value;
}
