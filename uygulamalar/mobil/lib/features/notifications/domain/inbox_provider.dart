import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_provider.dart';
import '../../../core/storage/inbox_prefs.dart';
import '../../auth/domain/auth_providers.dart';
import '../data/inbox_repository.dart';
import 'inbox_models.dart';

class InboxState {
  InboxState({
    required this.items,
    required this.readIds,
    required this.isLoading,
    this.error,
  });

  final List<InboxItem> items;
  final Set<String> readIds;
  final bool isLoading;
  final Object? error;

  bool isRead(InboxItem item) => item.isRead || readIds.contains(item.id);

  int get unreadCount => items.where((e) => !isRead(e)).length;

  factory InboxState.initial() =>
      InboxState(items: const [], readIds: const <String>{}, isLoading: true);

  InboxState copyWith({
    List<InboxItem>? items,
    Set<String>? readIds,
    bool? isLoading,
    Object? error,
  }) {
    return InboxState(
      items: items ?? this.items,
      readIds: readIds ?? this.readIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final inboxProvider = NotifierProvider<InboxController, InboxState>(
  InboxController.new,
);

final inboxUnreadCountProvider = Provider<int>((ref) {
  final st = ref.watch(inboxProvider);
  return st.unreadCount;
});

class InboxController extends Notifier<InboxState> {
  RealtimeChannel? _channel;

  @override
  InboxState build() {
    final user = ref.watch(userProvider);

    ref.onDispose(_disposeChannel);

    if (user == null) {
      _disposeChannel();
      return InboxState(
        items: const [],
        readIds: const <String>{},
        isLoading: false,
      );
    }

    _subscribeRealtime(user.id);
    Future.microtask(_loadWithCache);
    return InboxState.initial();
  }

  void _subscribeRealtime(String userId) {
    final client = ref.read(supabaseProvider);
    if (_channel != null) return;

    _channel = client
        .channel('inbox_notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            // Keep source of truth in DB and refresh quickly.
            refresh();
          },
        )
        .subscribe();
  }

  void _disposeChannel() {
    if (_channel == null) return;
    final client = ref.read(supabaseProvider);
    client.removeChannel(_channel!);
    _channel = null;
  }

  Future<void> _loadWithCache() async {
    // Show cached items immediately while fetching fresh data
    final cachedMaps = await InboxPrefs.getCachedItems();
    if (cachedMaps.isNotEmpty) {
      final cached = cachedMaps.map(InboxItem.fromMap).toList();
      final readIds = await InboxPrefs.getReadIds();
      state = state.copyWith(items: cached, readIds: readIds, isLoading: true);
    }
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(inboxRepositoryProvider);
      final items = await repo.listInboxItems();
      final readIds = await InboxPrefs.getReadIds();
      state = state.copyWith(items: items, readIds: readIds, isLoading: false);
      // Persist items for next cold start
      await InboxPrefs.cacheItems(items.map((e) => e.toMap()).toList());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> markRead(String id) async {
    final repo = ref.read(inboxRepositoryProvider);
    await repo.markRead(id);

    final next = {...state.readIds, id};
    state = state.copyWith(readIds: next);
    await InboxPrefs.saveReadIds(next);

    // Keep DB-backed rows synchronized.
    if (id.startsWith('db_')) {
      final updated = state.items
          .map(
            (e) => e.id == id
                ? InboxItem(
                    id: e.id,
                    type: e.type,
                    title: e.title,
                    message: e.message,
                    createdAt: e.createdAt,
                    targetPath: e.targetPath,
                    isRead: true,
                    meta: e.meta,
                  )
                : e,
          )
          .toList();
      state = state.copyWith(items: updated);
    }
  }

  Future<void> markAllRead() async {
    final repo = ref.read(inboxRepositoryProvider);
    await repo.markAllRead();

    final next = state.items.map((e) => e.id).toSet();
    state = state.copyWith(readIds: next);
    await InboxPrefs.saveReadIds(next);

    final updated = state.items
        .map(
          (e) => InboxItem(
            id: e.id,
            type: e.type,
            title: e.title,
            message: e.message,
            createdAt: e.createdAt,
            targetPath: e.targetPath,
            isRead: true,
            meta: e.meta,
          ),
        )
        .toList();
    state = state.copyWith(items: updated);
  }
}
