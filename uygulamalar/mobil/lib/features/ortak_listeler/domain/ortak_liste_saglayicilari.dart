import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ortak_liste_deposu.dart';
import 'ortak_liste_modelleri.dart';

// ── My lists ─────────────────────────────────────────────────────────────────

final myCollabListsProvider =
    AsyncNotifierProvider<MyCollabListsNotifier, List<CollabList>>(
  MyCollabListsNotifier.new,
);

class MyCollabListsNotifier extends AsyncNotifier<List<CollabList>> {
  @override
  Future<List<CollabList>> build() {
    return ref.read(collabListRepositoryProvider).fetchMyLists();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(collabListRepositoryProvider).fetchMyLists(),
    );
  }

  Future<void> createList({required String name, String? description}) async {
    final repo = ref.read(collabListRepositoryProvider);
    final newList = await repo.createList(name: name, description: description);
    final current = state.asData?.value ?? [];
    state = AsyncData([newList, ...current]);
  }

  Future<void> deleteList(String listId) async {
    final repo = ref.read(collabListRepositoryProvider);
    await repo.deleteList(listId);
    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((l) => l.id != listId).toList());
  }

  Future<void> leaveList(String listId) async {
    final repo = ref.read(collabListRepositoryProvider);
    await repo.leaveList(listId);
    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((l) => l.id != listId).toList());
  }
}

// ── Detail ────────────────────────────────────────────────────────────────────

final collabListDetailProvider = AsyncNotifierProvider.family<
    CollabListDetailNotifier, CollabListDetail, String>(
  CollabListDetailNotifier.new,
);

class CollabListDetailNotifier extends AsyncNotifier<CollabListDetail> {
  CollabListDetailNotifier(this.listId);
  final String listId;

  @override
  Future<CollabListDetail> build() {
    return ref.read(collabListRepositoryProvider).fetchDetail(listId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(collabListRepositoryProvider).fetchDetail(listId),
    );
  }

  Future<void> addItem(String businessId, {String? note}) async {
    final repo = ref.read(collabListRepositoryProvider);
    await repo.addItem(listId, businessId, note: note);
    await refresh();
  }

  Future<void> removeItem(String itemId) async {
    final repo = ref.read(collabListRepositoryProvider);
    await repo.removeItem(itemId);
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(CollabListDetail(
      list: current.list,
      items: current.items.where((i) => i.id != itemId).toList(),
    ));
  }

  Future<void> vote(String itemId, int vote) async {
    // Optimistic update
    final current = state.asData?.value;
    if (current != null) {
      final updatedItems = current.items.map((item) {
        if (item.id != itemId) return item;
        final delta = vote - item.myVote;
        return item.copyWith(
          myVote: vote,
          score: item.score + delta,
        );
      }).toList();
      state = AsyncData(
          CollabListDetail(list: current.list, items: updatedItems));
    }

    try {
      await ref.read(collabListRepositoryProvider).upsertVote(itemId, vote);
    } catch (_) {
      await refresh();
      rethrow;
    }
  }
}

