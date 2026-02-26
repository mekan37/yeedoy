import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/weather/weather_hint_provider.dart';
import '../data/smart_feed_repository.dart';
import 'smart_feed_models.dart';

final smartFeedProvider = NotifierProvider<SmartFeedController, SmartFeedState>(
  SmartFeedController.new,
);

class SmartFeedController extends Notifier<SmartFeedState> {
  static const int pageSize = 20;
  int _requestId = 0;
  int _loadMoreId = 0;
  Timer? _saveTimer;

  @override
  SmartFeedState build() {
    ref.onDispose(() => _saveTimer?.cancel());
    Future.microtask(loadInitial);
    return SmartFeedState.initial();
  }

  Future<void> loadInitial() async {
    final reqId = ++_requestId;
    state = state.copyWith(
      loading: true,
      isLoadingMore: false,
      items: [],
      hasMore: true,
      error: null,
    );
    try {
      final prefs = await ref
          .read(smartFeedRepositoryProvider)
          .getPreferences();
      if (reqId != _requestId) return;
      await _loadInitialWithPrefs(prefs, reqId: reqId);
    } catch (e) {
      if (reqId != _requestId) return;
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> _loadInitialWithPrefs(
    SmartFeedPreferences prefs, {
    required int reqId,
  }) async {
    state = state.copyWith(
      preferences: prefs,
      loading: true,
      isLoadingMore: false,
      items: [],
      hasMore: true,
      error: null,
    );
    final context = await _resolveContext();
    final list = await ref
        .read(smartFeedRepositoryProvider)
        .getSmartFeed(
          limit: pageSize,
          offset: 0,
          prefs: prefs,
          weatherHint: context.weatherHint,
          timeLabel: context.timeLabel,
          dayLabel: context.dayLabel,
        );
    if (reqId != _requestId) return;
    state = state.copyWith(
      loading: false,
      items: list,
      hasMore: list.length == pageSize,
      error: null,
      preferences: prefs,
    );
  }

  Future<void> loadMore() async {
    if (state.loading || state.isLoadingMore || !state.hasMore) return;
    final baseReqId = _requestId;
    final loadMoreId = ++_loadMoreId;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final context = await _resolveContext();
      final list = await ref
          .read(smartFeedRepositoryProvider)
          .getSmartFeed(
            limit: pageSize,
            offset: state.items.length,
            prefs: state.preferences,
            weatherHint: context.weatherHint,
            timeLabel: context.timeLabel,
            dayLabel: context.dayLabel,
          );
      if (baseReqId != _requestId || loadMoreId != _loadMoreId) return;
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...list],
        hasMore: list.length == pageSize,
      );
    } catch (e) {
      if (baseReqId != _requestId || loadMoreId != _loadMoreId) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> updatePreferences(SmartFeedPreferences prefs) async {
    final reqId = ++_requestId;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      ref.read(smartFeedRepositoryProvider).upsertPreferences(prefs);
    });
    await _loadInitialWithPrefs(prefs, reqId: reqId);
  }

  Future<void> setLocation({
    required String city,
    required String district,
  }) async {
    final next = state.preferences.copyWith(
      city: city,
      districts: district.isEmpty ? [] : [district],
    );
    await updatePreferences(next);
  }

  Future<_SmartContext> _resolveContext() async {
    final now = DateTime.now();
    final weatherHint = await ref.read(weatherHintProvider.future);
    return _SmartContext(
      dayLabel: _dayPartLabel(now),
      timeLabel: _timePartLabel(now),
      weatherHint: weatherHint,
    );
  }
}

class _SmartContext {
  const _SmartContext({
    required this.dayLabel,
    required this.timeLabel,
    required this.weatherHint,
  });

  final String dayLabel;
  final String timeLabel;
  final String? weatherHint;
}

String _dayPartLabel(DateTime now) {
  final wd = now.weekday;
  if (wd == DateTime.saturday || wd == DateTime.sunday) {
    return 'Hafta sonu';
  }
  return 'Hafta içi';
}

String _timePartLabel(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 11) return 'Sabah';
  if (hour >= 11 && hour < 16) return 'Öğle';
  if (hour >= 16 && hour < 22) return 'Akşam';
  return 'Gece';
}

