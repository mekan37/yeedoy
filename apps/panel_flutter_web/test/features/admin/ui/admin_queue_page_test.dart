import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeedoy/app/theme/app_tokens.dart';
import 'package:yeedoy/features/admin/data/admin_audit_repository.dart';
import 'package:yeedoy/features/admin/data/admin_queue_repository.dart';
import 'package:yeedoy/features/admin/domain/admin_audit_models.dart';
import 'package:yeedoy/features/admin/domain/admin_queue_models.dart';
import 'package:yeedoy/features/admin/ui/admin_queue_page.dart';
import 'package:yeedoy/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'admin queue detail shows decision support and history context',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final item = AdminQueueItem(
        id: 'price-1',
        type: AdminQueueItemType.priceSuggestion,
        status: 'pending',
        createdAt: DateTime(2026, 3, 6, 12),
        ageHours: 6,
        slaHours: 48,
        slaBreached: false,
        title: 'Latte',
        subtitle: '120 -> 220 TRY',
        businessId: 'business-1',
        businessName: 'Cafe Nova',
        city: 'Istanbul',
        district: 'Kadikoy',
        detail: const {
          'quality_confidence': 0.42,
          'anomaly_score': 0.81,
          'conflict_state': 'queued',
          'conflict_variants_24h': 3,
          'anomaly_flags': ['price_conflict', 'high_increase'],
          'created_by_reputation': 32,
          'created_by_risk_score': 66,
          'business_quality_score': 44.0,
        },
        totalCount: 1,
      );

      final queueRepo = _FakeAdminQueueRepository(
        AdminQueuePageResult(items: [item], totalCount: 1),
      );
      final auditRepo = _FakeAdminAuditRepository([
        AdminAuditLogItem(
          createdAt: DateTime(2026, 3, 6, 11, 30),
          actorId: 'admin-1',
          actorRole: 'admin',
          action: 'price_suggestion.approved',
          targetType: 'price_suggestion',
          targetId: 'price-2',
        ),
        AdminAuditLogItem(
          createdAt: DateTime(2026, 3, 6, 11, 0),
          actorId: 'admin-2',
          actorRole: 'admin',
          action: 'price_suggestion.assigned',
          targetType: 'price_suggestion',
          targetId: 'price-1',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminQueueRepositoryProvider.overrideWithValue(queueRepo),
            adminAuditRepositoryProvider.overrideWithValue(auditRepo),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              extensions: const <ThemeExtension<dynamic>>[
                AppTokens(
                  space4: 4,
                  space8: 8,
                  space12: 12,
                  space16: 16,
                  space20: 20,
                  space24: 24,
                  radius12: 12,
                  radius16: 16,
                  radius20: 20,
                  radius24: 24,
                  elevation1: 1,
                  elevation2: 6,
                  elevation3: 12,
                  minHitTarget: 44,
                  fast: Duration(milliseconds: 150),
                  medium: Duration(milliseconds: 180),
                  slow: Duration(milliseconds: 220),
                ),
              ],
            ),
            home: const Scaffold(body: AdminQueuePage()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Latte'), findsOneWidget);

      await tester.tap(find.text('Latte'));
      await tester.pumpAndSettle();

      expect(find.text('Karar desteği'), findsOneWidget);
      expect(find.text('Benzer karar geçmişi'), findsOneWidget);
      expect(
        find.textContaining('Neden beklemede', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Çakışan fiyatlar ve yüksek anomali nedeniyle sırada.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.textContaining('2 ilgili kayıt'), findsOneWidget);
      expect(find.text('Fiyat önerisi onaylandı'), findsOneWidget);
    },
  );
}

class _FakeAdminQueueRepository extends AdminQueueRepository {
  _FakeAdminQueueRepository(this._result)
    : super(SupabaseClient('http://localhost:54321', 'test-key'));

  final AdminQueuePageResult _result;

  @override
  Future<AdminQueuePageResult> listQueue({
    String? type,
    String? status,
    String? city,
    String? query,
    DateTime? from,
    DateTime? to,
    String sortKey = 'created_at',
    bool sortAscending = false,
    int limit = 20,
    int offset = 0,
  }) async {
    return _result;
  }

  @override
  Future<void> setAssignment({
    required AdminQueueItemType type,
    required String itemId,
    required bool assignToMe,
  }) async {}
}

class _FakeAdminAuditRepository extends AdminAuditRepository {
  _FakeAdminAuditRepository(this._items)
    : super(SupabaseClient('http://localhost:54321', 'test-key'));

  final List<AdminAuditLogItem> _items;

  @override
  Future<List<AdminAuditLogItem>> fetchLogs({
    int limit = 50,
    int offset = 0,
    String? actionFilter,
    String? targetTypeFilter,
    String? actorFilter,
    String? targetId,
    String? businessId,
    DateTime? from,
    DateTime? to,
    String? query,
  }) async {
    return _items.take(limit).toList(growable: false);
  }
}
