import 'menu_item_search_model.dart';

class MenuItemSearchState {
  const MenuItemSearchState({
    required this.items,
    required this.loading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.query,
    required this.radiusKm,
    required this.vegan,
    required this.vegetarian,
    required this.glutenFree,
    required this.lactoseFree,
    required this.halal,
    required this.verifiedPriceOnly,
    required this.maxCalories,
    required this.profileEnabled,
    required this.manualVegan,
    required this.manualVegetarian,
    required this.manualGlutenFree,
    required this.manualLactoseFree,
    required this.manualHalal,
    required this.manualMaxCalories,
    required this.profileVegan,
    required this.profileVegetarian,
    required this.profileGlutenFree,
    required this.profileLactoseFree,
    required this.profileHalal,
    required this.profileMaxCalories,
    this.error,
    this.userLat,
    this.userLng,
    this.needsLocation = false,
  });

  final List<MenuItemSearchResult> items;
  final bool loading;
  final bool isLoadingMore;
  final bool hasMore;
  final String query;
  final int radiusKm;
  final bool vegan;
  final bool vegetarian;
  final bool glutenFree;
  final bool lactoseFree;
  final bool halal;
  final bool verifiedPriceOnly;
  final int? maxCalories;
  final bool profileEnabled;
  final bool manualVegan;
  final bool manualVegetarian;
  final bool manualGlutenFree;
  final bool manualLactoseFree;
  final bool manualHalal;
  final int? manualMaxCalories;
  final bool profileVegan;
  final bool profileVegetarian;
  final bool profileGlutenFree;
  final bool profileLactoseFree;
  final bool profileHalal;
  final int? profileMaxCalories;
  final Object? error;
  final double? userLat;
  final double? userLng;
  final bool needsLocation;

  factory MenuItemSearchState.initial() => const MenuItemSearchState(
        items: [],
        loading: false,
        isLoadingMore: false,
        hasMore: true,
        query: '',
        radiusKm: 5,
        vegan: false,
        vegetarian: false,
        glutenFree: false,
        lactoseFree: false,
        halal: false,
        verifiedPriceOnly: false,
        maxCalories: 1200,
        profileEnabled: false,
        manualVegan: false,
        manualVegetarian: false,
        manualGlutenFree: false,
        manualLactoseFree: false,
        manualHalal: false,
        manualMaxCalories: 1200,
        profileVegan: false,
        profileVegetarian: false,
        profileGlutenFree: false,
        profileLactoseFree: false,
        profileHalal: false,
        profileMaxCalories: null,
        error: null,
        userLat: null,
        userLng: null,
        needsLocation: false,
      );

  MenuItemSearchState copyWith({
    List<MenuItemSearchResult>? items,
    bool? loading,
    bool? isLoadingMore,
    bool? hasMore,
    String? query,
    int? radiusKm,
    bool? vegan,
    bool? vegetarian,
    bool? glutenFree,
    bool? lactoseFree,
    bool? halal,
    bool? verifiedPriceOnly,
    int? maxCalories,
    bool? profileEnabled,
    bool? manualVegan,
    bool? manualVegetarian,
    bool? manualGlutenFree,
    bool? manualLactoseFree,
    bool? manualHalal,
    int? manualMaxCalories,
    bool? profileVegan,
    bool? profileVegetarian,
    bool? profileGlutenFree,
    bool? profileLactoseFree,
    bool? profileHalal,
    int? profileMaxCalories,
    Object? error,
    double? userLat,
    double? userLng,
    bool? needsLocation,
  }) {
    return MenuItemSearchState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      radiusKm: radiusKm ?? this.radiusKm,
      vegan: vegan ?? this.vegan,
      vegetarian: vegetarian ?? this.vegetarian,
      glutenFree: glutenFree ?? this.glutenFree,
      lactoseFree: lactoseFree ?? this.lactoseFree,
      halal: halal ?? this.halal,
      verifiedPriceOnly: verifiedPriceOnly ?? this.verifiedPriceOnly,
      maxCalories: maxCalories ?? this.maxCalories,
      profileEnabled: profileEnabled ?? this.profileEnabled,
      manualVegan: manualVegan ?? this.manualVegan,
      manualVegetarian: manualVegetarian ?? this.manualVegetarian,
      manualGlutenFree: manualGlutenFree ?? this.manualGlutenFree,
      manualLactoseFree: manualLactoseFree ?? this.manualLactoseFree,
      manualHalal: manualHalal ?? this.manualHalal,
      manualMaxCalories: manualMaxCalories ?? this.manualMaxCalories,
      profileVegan: profileVegan ?? this.profileVegan,
      profileVegetarian: profileVegetarian ?? this.profileVegetarian,
      profileGlutenFree: profileGlutenFree ?? this.profileGlutenFree,
      profileLactoseFree: profileLactoseFree ?? this.profileLactoseFree,
      profileHalal: profileHalal ?? this.profileHalal,
      profileMaxCalories: profileMaxCalories ?? this.profileMaxCalories,
      error: error,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      needsLocation: needsLocation ?? this.needsLocation,
    );
  }
}
