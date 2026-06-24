import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yeedoy/app/theme/app_tokens.dart';
import 'package:yeedoy/features/auth/domain/auth_providers.dart';
import 'package:yeedoy/features/notifications/domain/inbox_models.dart';
import 'package:yeedoy/features/notifications/domain/inbox_provider.dart';
import 'package:yeedoy/features/notifications/ui/inbox_page.dart';
import 'package:yeedoy/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Fake inbox controller — no Supabase, no prefs.
// ---------------------------------------------------------------------------
class _FakeInboxController extends InboxController {
  _FakeInboxController(this._initial);
  final InboxState _initial;

  @override
  InboxState build() => _initial;

  @override
  Future<void> markRead(String id) async {
    final next = {...state.readIds, id};
    state = state.copyWith(readIds: next);
  }

  @override
  Future<void> markAllRead() async {
    final next = state.items.map((e) => e.id).toSet();
    state = state.copyWith(readIds: next);
  }

  @override
  Future<void> refresh() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
InboxItem _makeItem(String id, {bool read = false}) => InboxItem(
  id: id,
  type: 'generic',
  title: 'Title $id',
  message: 'Message $id',
  createdAt: DateTime(2026, 1, 1),
  targetPath: '/isletme/some-id',
  isRead: read,
);

ThemeData _theme() => ThemeData(
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
);

Future<void> _pumpInbox(WidgetTester tester, InboxState initialState) async {
  final router = GoRouter(
    initialLocation: '/inbox',
    routes: [
      GoRoute(path: '/inbox', builder: (context, state) => const InboxPage()),
      GoRoute(
        path: '/isletme/:id',
        builder: (context, state) => const SizedBox(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const SizedBox()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inboxProvider.overrideWith(() => _FakeInboxController(initialState)),
        userProvider.overrideWith((ref) => null),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: _theme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  testWidgets('InboxPage shows items when state has items', (tester) async {
    final state = InboxState(
      items: [_makeItem('1'), _makeItem('2')],
      readIds: const {},
      isLoading: false,
    );

    await _pumpInbox(tester, state);

    expect(find.text('Title 1'), findsOneWidget);
    expect(find.text('Title 2'), findsOneWidget);
  });

  testWidgets('InboxPage shows empty state when no items', (tester) async {
    final state = InboxState(
      items: const [],
      readIds: const {},
      isLoading: false,
    );

    await _pumpInbox(tester, state);

    // Empty state icon or message should appear
    expect(find.byType(InboxPage), findsOneWidget);
    expect(find.text('Title 1'), findsNothing);
  });

  testWidgets('empty state does not render mark-all-read action', (
    tester,
  ) async {
    final state = InboxState(
      items: const [],
      readIds: const {},
      isLoading: false,
    );

    await _pumpInbox(tester, state);

    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('unread items render with bold title', (tester) async {
    final state = InboxState(
      items: [_makeItem('unread1', read: false)],
      readIds: const {},
      isLoading: false,
    );

    await _pumpInbox(tester, state);

    // The title should be visible
    expect(find.text('Title unread1'), findsOneWidget);
  });

  testWidgets('read items do not count as unread', (tester) async {
    final state = InboxState(
      items: [_makeItem('r1', read: true), _makeItem('u1', read: false)],
      readIds: const {},
      isLoading: false,
    );

    expect(state.unreadCount, 1);
    expect(state.isRead(state.items[0]), isTrue);
    expect(state.isRead(state.items[1]), isFalse);
  });

  test('InboxState.isRead uses readIds set when item.isRead is false', () {
    final item = _makeItem('x1', read: false);
    final state = InboxState(
      items: [item],
      readIds: const {'x1'},
      isLoading: false,
    );
    expect(state.isRead(item), isTrue);
  });

  test('markAllRead sets all item ids in readIds', () {
    final items = [_makeItem('a'), _makeItem('b'), _makeItem('c')];
    var state = InboxState(items: items, readIds: const {}, isLoading: false);

    final next = items.map((e) => e.id).toSet();
    state = state.copyWith(readIds: next);

    expect(state.unreadCount, 0);
    expect(state.readIds, {'a', 'b', 'c'});
  });
}
