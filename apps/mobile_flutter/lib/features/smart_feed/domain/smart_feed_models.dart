import 'package:flutter/foundation.dart';

@immutable
class SmartFeedEvent {
  const SmartFeedEvent({
    required this.eventType,
    required this.businessId,
    required this.businessName,
    required this.createdAt,
    required this.payload,
    required this.refType,
    required this.refId,
  });

  final String eventType;
  final String businessId;
  final String businessName;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final String? refType;
  final String? refId;

  factory SmartFeedEvent.fromMap(Map<String, dynamic> map) {
    return SmartFeedEvent(
      eventType: (map['event_type'] ?? '').toString(),
      businessId: (map['business_id'] ?? '').toString(),
      businessName: (map['business_name'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
      payload: (map['payload'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
      refType: map['ref_type']?.toString(),
      refId: map['ref_id']?.toString(),
    );
  }
}

@immutable
class SmartFeedPreferences {
  const SmartFeedPreferences({
    required this.categories,
    required this.bundles,
    required this.priceMaxCents,
    required this.city,
    required this.districts,
  });

  final List<String> categories;
  final List<String> bundles;
  final int? priceMaxCents;
  final String? city;
  final List<String> districts;

  SmartFeedPreferences copyWith({
    List<String>? categories,
    List<String>? bundles,
    int? priceMaxCents,
    String? city,
    List<String>? districts,
  }) {
    return SmartFeedPreferences(
      categories: categories ?? this.categories,
      bundles: bundles ?? this.bundles,
      priceMaxCents: priceMaxCents ?? this.priceMaxCents,
      city: city ?? this.city,
      districts: districts ?? this.districts,
    );
  }

  factory SmartFeedPreferences.empty() {
    return const SmartFeedPreferences(
      categories: [],
      bundles: [],
      priceMaxCents: null,
      city: null,
      districts: [],
    );
  }

  factory SmartFeedPreferences.fromMap(Map<String, dynamic> map) {
    return SmartFeedPreferences(
      categories: _stringList(map['categories']),
      bundles: _stringList(map['bundles']),
      priceMaxCents: (map['price_max_cents'] as num?)?.toInt(),
      city: map['city']?.toString(),
      districts: _stringList(map['districts']),
    );
  }

  Map<String, dynamic> toMap({required String userId}) {
    return {
      'user_id': userId,
      'categories': categories,
      'bundles': bundles,
      'price_max_cents': priceMaxCents,
      'city': city,
      'districts': districts,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const <String>[];
  }
}

@immutable
class SmartFeedState {
  const SmartFeedState({
    required this.items,
    required this.loading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.preferences,
  });

  final List<SmartFeedEvent> items;
  final bool loading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final SmartFeedPreferences preferences;

  factory SmartFeedState.initial() {
    return SmartFeedState(
      items: const [],
      loading: true,
      isLoadingMore: false,
      hasMore: true,
      error: null,
      preferences: SmartFeedPreferences.empty(),
    );
  }

  SmartFeedState copyWith({
    List<SmartFeedEvent>? items,
    bool? loading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    SmartFeedPreferences? preferences,
  }) {
    return SmartFeedState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      preferences: preferences ?? this.preferences,
    );
  }
}
