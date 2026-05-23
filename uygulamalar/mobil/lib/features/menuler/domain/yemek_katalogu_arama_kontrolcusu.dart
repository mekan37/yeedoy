// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/yemek_katalogu_deposu.dart';
import 'yemek_katalogu_modelleri.dart';

final foodCatalogSearchProvider =
    NotifierProvider<FoodCatalogSearchController, FoodCatalogSearchState>(
  FoodCatalogSearchController.new,
);

class FoodCatalogSearchState {
  const FoodCatalogSearchState({
    required this.query,
    required this.results,
    required this.isLoading,
    this.error,
  });

  final String query;
  final List<FoodCatalogHit> results;
  final bool isLoading;
  final Object? error;

  factory FoodCatalogSearchState.initial() => const FoodCatalogSearchState(
        query: '',
        results: [],
        isLoading: false,
        error: null,
      );

  FoodCatalogSearchState copyWith({
    String? query,
    List<FoodCatalogHit>? results,
    bool? isLoading,
    Object? error,
  }) {
    return FoodCatalogSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FoodCatalogSearchController extends Notifier<FoodCatalogSearchState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  FoodCatalogSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return FoodCatalogSearchState.initial();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query, error: null);
    _debounce?.cancel();
    if (query.trim().length < 2) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _search(query.trim());
    });
  }

  void clear() {
    state = state.copyWith(query: '', results: [], isLoading: false, error: null);
  }

  Future<void> retry() async {
    final query = state.query.trim();
    if (query.length < 2) return;
    await _search(query);
  }

  Future<void> _search(String query) async {
    final reqId = ++_requestId;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await ref.read(foodCatalogRepositoryProvider).search(query, limit: 12);
      if (reqId != _requestId) return;
      state = state.copyWith(isLoading: false, results: results);
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(isLoading: false, error: e, results: []);
    }
  }
}

