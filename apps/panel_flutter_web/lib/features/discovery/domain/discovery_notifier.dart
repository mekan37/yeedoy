import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/discovery_repo.dart';
import '../../business/domain/business.dart';

final discoveryProvider =
    AsyncNotifierProvider<DiscoveryNotifier, List<Business>>(
      DiscoveryNotifier.new,
    );

class DiscoveryNotifier extends AsyncNotifier<List<Business>> {
  String _q = '';
  String _category = '';

  bool _sameItems(List<Business> a, List<Business> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  Future<List<Business>> build() async {
    final swr = await ref.read(discoveryRepoProvider).listBusinessesSWR();
    if (swr.refresh != null) {
      swr.refresh!.then((fresh) {
        final current = state.asData?.value;
        if (current == null || !_sameItems(current, fresh)) {
          state = AsyncData(fresh);
        }
      });
    }
    return swr.data;
  }

  Future<void> search({String? query, String? category}) async {
    _q = query ?? _q;
    _category = category ?? _category;

    final previous = state.asData?.value;
    if (previous != null && previous.isNotEmpty) {
      state = AsyncData(previous);
    } else {
      state = const AsyncLoading();
    }
    final swr = await ref
        .read(discoveryRepoProvider)
        .listBusinessesSWR(query: _q, category: _category);
    state = AsyncData(swr.data);
    if (swr.refresh != null) {
      swr.refresh!.then((fresh) {
        final current = state.asData?.value;
        if (current == null || !_sameItems(current, fresh)) {
          state = AsyncData(fresh);
        }
      });
    }
  }
}
