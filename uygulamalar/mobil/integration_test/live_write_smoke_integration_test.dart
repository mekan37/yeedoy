import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeedoy/core/cache/request_cache.dart';
import 'package:yeedoy/core/analytics/analytics_repository.dart';
import 'package:yeedoy/core/monitoring/app_telemetry.dart';
import 'package:yeedoy/core/storage/local_db/memory_local_db_store.dart';
import 'package:yeedoy/features/business/data/report_repository.dart';
import 'package:yeedoy/features/favorites/data/favorites_repository.dart';
import 'package:yeedoy/features/menus/data/menu_repository.dart';
import 'package:yeedoy/features/reviews/data/reviews_repository.dart';

const _runLiveWriteSmoke = bool.fromEnvironment(
  'RUN_LIVE_WRITE_SMOKE',
  defaultValue: false,
);

const _liveSupabaseUrl = String.fromEnvironment('LIVE_SUPABASE_URL');
const _liveSupabaseAnonKey = String.fromEnvironment('LIVE_SUPABASE_ANON_KEY');
const _liveSmokeEmail = String.fromEnvironment('LIVE_SMOKE_EMAIL');
const _liveSmokePassword = String.fromEnvironment('LIVE_SMOKE_PASSWORD');
const _liveSmokeBusinessId = String.fromEnvironment('LIVE_SMOKE_BUSINESS_ID');
const _liveSmokeMenuItemId = String.fromEnvironment('LIVE_SMOKE_MENU_ITEM_ID');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'live backend write smoke covers review/report/menu/favorites + unauth fail path',
    (tester) async {
      final config = _LiveSmokeConfig.fromEnvironment();
      final missing = config.missingKeys;
      expect(
        missing,
        isEmpty,
        reason:
            'Missing dart-defines: ${missing.join(', ')}. '
            'Set RUN_LIVE_WRITE_SMOKE=true and provide all LIVE_* values.',
      );

      final client = SupabaseClient(config.supabaseUrl, config.supabaseAnonKey);
      final reviewsRepository = ReviewsRepository(client);
      final reportRepository = ReportRepository(client);
      final favoritesRepository = FavoritesRepository(client);
      final localDbStore = MemoryLocalDbStore();
      await localDbStore.initialize();
      final menuRepository = MenuRepository(
        client,
        AppTelemetry(AnalyticsRepository(client)),
        RequestCache.shared,
        localDbStore,
      );
      final nonce = DateTime.now().toUtc().millisecondsSinceEpoch;

      addTearDown(() async {
        await client.auth.signOut();
      });

      final signInRes = await client.auth.signInWithPassword(
        email: config.email,
        password: config.password,
      );
      expect(signInRes.session, isNotNull, reason: 'Live smoke login failed');

      await _assertAllowedWriteOutcome(
        operation: 'submit_review_v1',
        allowedErrors: const [
          'same_business_cooldown',
          'new_account_rate_limited',
          'review_daily_rate_limited',
          'rate_limited_',
        ],
        run: () async {
          await reviewsRepository.createReview(
            businessId: config.businessId,
            rating: 4,
            title: 'live smoke $nonce',
            content: 'live smoke review $nonce',
          );
        },
      );

      await _assertAllowedWriteOutcome(
        operation: 'submit_menu_item_price_suggestion_v3',
        allowedErrors: const [
          'price_suggestion_same_item_cooldown',
          'price_suggestion_daily_rate_limited',
          'rate_limited_',
          'contact_verification_required',
        ],
        run: () async {
          await menuRepository.submitMenuItemPriceSuggestion(
            menuItemId: config.menuItemId,
            suggestedPriceCents: 12300,
            currency: 'TRY',
            note: 'live_write_smoke_$nonce',
            queueOnOffline: false,
          );
        },
      );

      await _assertAllowedWriteOutcome(
        operation: 'submit_report_v1',
        allowedErrors: const ['rate_limited_24h', 'rate_limited_'],
        run: () async {
          final res = await reportRepository.submitBusinessReport(
            businessId: config.businessId,
            reason: 'wrong_info',
            details: 'live smoke report $nonce',
          );
          if (!res.ok) {
            final raw = (res.error ?? 'unknown').toLowerCase();
            if (!_containsAny(raw, const [
              'rate_limited_24h',
              'rate_limited_',
            ])) {
              throw Exception(
                'submit_report_v1 unexpected error: ${res.error}',
              );
            }
          }
        },
      );

      final wasFavorited = await favoritesRepository.isFavorited(
        config.businessId,
      );
      await _assertAllowedWriteOutcome(
        operation: 'toggle_favorite_v1:add_or_remove',
        allowedErrors: const ['rate_limited_', 'business_not_found'],
        run: () async {
          await favoritesRepository.toggleFavorite(config.businessId);
        },
      );
      await _assertAllowedWriteOutcome(
        operation: 'toggle_favorite_v1:restore_previous_state',
        allowedErrors: const ['rate_limited_', 'business_not_found'],
        run: () async {
          await favoritesRepository.toggleFavorite(config.businessId);
        },
      );
      final restoredFavorited = await favoritesRepository.isFavorited(
        config.businessId,
      );
      expect(
        restoredFavorited,
        wasFavorited,
        reason: 'Favorites smoke should restore initial favorite state',
      );

      await client.auth.signOut();
      expect(client.auth.currentSession, isNull);

      Object? unauthError;
      try {
        await reviewsRepository.createReview(
          businessId: config.businessId,
          rating: 4,
          title: 'should fail',
          content: 'unauthenticated write should fail',
        );
      } catch (error) {
        unauthError = error;
      }

      expect(unauthError, isNotNull, reason: 'Unauthenticated write must fail');
      expect(
        _containsAny(unauthError.toString().toLowerCase(), const [
          'not_authenticated',
          'auth',
          'session',
          'jwt',
        ]),
        isTrue,
        reason:
            'Unexpected unauthenticated error text: ${unauthError.toString()}',
      );
    },
    skip: !_runLiveWriteSmoke,
  );
}

class _LiveSmokeConfig {
  const _LiveSmokeConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.email,
    required this.password,
    required this.businessId,
    required this.menuItemId,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String email;
  final String password;
  final String businessId;
  final String menuItemId;

  static _LiveSmokeConfig fromEnvironment() {
    return const _LiveSmokeConfig(
      supabaseUrl: _liveSupabaseUrl,
      supabaseAnonKey: _liveSupabaseAnonKey,
      email: _liveSmokeEmail,
      password: _liveSmokePassword,
      businessId: _liveSmokeBusinessId,
      menuItemId: _liveSmokeMenuItemId,
    );
  }

  List<String> get missingKeys {
    final missing = <String>[];
    if (supabaseUrl.trim().isEmpty) missing.add('LIVE_SUPABASE_URL');
    if (supabaseAnonKey.trim().isEmpty) missing.add('LIVE_SUPABASE_ANON_KEY');
    if (email.trim().isEmpty) missing.add('LIVE_SMOKE_EMAIL');
    if (password.trim().isEmpty) missing.add('LIVE_SMOKE_PASSWORD');
    if (businessId.trim().isEmpty) missing.add('LIVE_SMOKE_BUSINESS_ID');
    if (menuItemId.trim().isEmpty) missing.add('LIVE_SMOKE_MENU_ITEM_ID');
    return missing;
  }
}

Future<void> _assertAllowedWriteOutcome({
  required String operation,
  required List<String> allowedErrors,
  required Future<void> Function() run,
}) async {
  try {
    await run();
    return;
  } catch (error) {
    final raw = error.toString().toLowerCase();
    if (_containsAny(raw, allowedErrors)) return;
    fail('$operation failed with unexpected error: ${error.toString()}');
  }
}

bool _containsAny(String raw, List<String> needles) {
  for (final needle in needles) {
    if (raw.contains(needle.toLowerCase())) return true;
  }
  return false;
}
