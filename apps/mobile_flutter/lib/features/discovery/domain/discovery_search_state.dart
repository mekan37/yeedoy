import '../domain/business_card.dart';

enum DiscoveryMode { nearby, text }
enum DiscoverySort { recommended, distance, rating, priceLow, newlyVerified }
enum DiscoveryPriceTier { any, budget, medium, premium }

class DiscoverySearchState {
  const DiscoverySearchState({
    required this.items,
    required this.loading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.query,
    required this.city,
    required this.district,
    required this.category,
    required this.mode,
    this.error,
    this.radiusKm = 10,
    this.userLat,
    this.userLng,
    this.openNow = false,
    this.minRating = 0,
    this.priceTier = DiscoveryPriceTier.any,
    this.sortBy = DiscoverySort.recommended,
    this.recentPriceBoost = true,
    this.mealCardKeys = const [],
    this.maxBudgetCents,
    this.tasteTwinEnabled = false,
  });

  final List<BusinessCardModel> items;
  final bool loading;
  final bool isLoadingMore;
  final bool hasMore;

  final String query;
  final String city;
  final String district;
  final String category;
  final DiscoveryMode mode;

  final Object? error;

  final int radiusKm;
  final double? userLat;
  final double? userLng;
  final bool openNow;
  final double minRating;
  final DiscoveryPriceTier priceTier;
  final DiscoverySort sortBy;
  final bool recentPriceBoost;
  final List<String> mealCardKeys;

  /// Max per-person budget in cents. Null = no limit.
  final int? maxBudgetCents;

  /// When true, Taste Twin recommendations boost matching businesses in the
  /// discovery feed. Feature-flag gated: only active for authenticated users
  /// who opt in (toggle in discovery controls).
  final bool tasteTwinEnabled;

  bool get hasBudgetFilter => maxBudgetCents != null && maxBudgetCents! > 0;

  factory DiscoverySearchState.initial() => const DiscoverySearchState(
        items: [],
        loading: false,
        isLoadingMore: false,
        hasMore: true,
        query: '',
        city: 'Ankara',
        district: 'Yenimahalle',
        category: '',
        mode: DiscoveryMode.text,
        error: null,
        radiusKm: 10,
        userLat: null,
        userLng: null,
        openNow: false,
        minRating: 0,
        priceTier: DiscoveryPriceTier.any,
        sortBy: DiscoverySort.recommended,
        recentPriceBoost: true,
        mealCardKeys: <String>[],
        maxBudgetCents: null,
        tasteTwinEnabled: false,
      );

  DiscoverySearchState copyWith({
    List<BusinessCardModel>? items,
    bool? loading,
    bool? isLoadingMore,
    bool? hasMore,
    String? query,
    String? city,
    String? district,
    String? category,
    DiscoveryMode? mode,
    Object? error,
    int? radiusKm,
    double? userLat,
    double? userLng,
    bool? openNow,
    double? minRating,
    DiscoveryPriceTier? priceTier,
    DiscoverySort? sortBy,
    bool? recentPriceBoost,
    List<String>? mealCardKeys,
    // Nullable sentinel: use Object? to allow explicit null pass-through
    Object? maxBudgetCents = _sentinel,
    bool? tasteTwinEnabled,
  }) {
    return DiscoverySearchState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      city: city ?? this.city,
      district: district ?? this.district,
      category: category ?? this.category,
      mode: mode ?? this.mode,
      error: error,
      radiusKm: radiusKm ?? this.radiusKm,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      openNow: openNow ?? this.openNow,
      minRating: minRating ?? this.minRating,
      priceTier: priceTier ?? this.priceTier,
      sortBy: sortBy ?? this.sortBy,
      recentPriceBoost: recentPriceBoost ?? this.recentPriceBoost,
      mealCardKeys: mealCardKeys ?? this.mealCardKeys,
      maxBudgetCents: identical(maxBudgetCents, _sentinel)
          ? this.maxBudgetCents
          : maxBudgetCents as int?,
      tasteTwinEnabled: tasteTwinEnabled ?? this.tasteTwinEnabled,
    );
  }
}

// Sentinel for nullable copyWith params.
const Object _sentinel = Object();
