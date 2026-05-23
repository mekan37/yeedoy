import 'package:flutter_riverpod/flutter_riverpod.dart';

class CompareController extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  static const int maxItems = 3;

  bool contains(String businessId) => state.contains(businessId);

  bool canAdd(String businessId) {
    return state.contains(businessId) || state.length < maxItems;
  }

  bool add(String businessId) {
    if (state.contains(businessId)) return true;
    if (state.length >= maxItems) return false;
    state = [...state, businessId];
    return true;
  }

  void remove(String businessId) {
    state = state.where((id) => id != businessId).toList(growable: false);
  }

  void toggle(String businessId) {
    if (state.contains(businessId)) {
      remove(businessId);
    } else {
      add(businessId);
    }
  }

  void clear() {
    state = const [];
  }
}

final compareControllerProvider =
    NotifierProvider<CompareController, List<String>>(CompareController.new);
