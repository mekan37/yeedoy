class DiscoveryCategoryConfig {
  const DiscoveryCategoryConfig({
    required this.id,
    required this.titleKey,
    required this.searchTerm,
    required this.imagePool,
  });

  final String id;
  final String titleKey;
  final String searchTerm;
  final List<String> imagePool;
}

class DiscoveryFilterConfig {
  const DiscoveryFilterConfig({
    required this.value,
    required this.labelKey,
  });

  final String value;
  final String labelKey;
}

const discoveryFilterConfigs = <DiscoveryFilterConfig>[
  DiscoveryFilterConfig(value: 'Kafe', labelKey: 'discoveryFilterCafe'),
  DiscoveryFilterConfig(
    value: 'Restoran',
    labelKey: 'discoveryFilterRestaurant',
  ),
  DiscoveryFilterConfig(
    value: 'Tatlı / Pastane',
    labelKey: 'discoveryFilterDessertPastry',
  ),
  DiscoveryFilterConfig(
    value: 'Kahvaltı',
    labelKey: 'discoveryFilterBreakfast',
  ),
  DiscoveryFilterConfig(
    value: 'Balık / Et',
    labelKey: 'discoveryFilterFishMeat',
  ),
  DiscoveryFilterConfig(value: 'Mekan', labelKey: 'discoveryFilterVenue'),
];

const discoveryHomeCategories = <DiscoveryCategoryConfig>[
  DiscoveryCategoryConfig(
    id: 'doner',
    titleKey: 'discoveryHomeCategoryDoner',
    searchTerm: 'döner',
    imagePool: [
      'assets/images/categories/doner.webp',
      'assets/images/categories/tantuni.webp',
    ],
  ),
  DiscoveryCategoryConfig(
    id: 'pide',
    titleKey: 'discoveryHomeCategoryPide',
    searchTerm: 'pide',
    imagePool: ['assets/images/categories/pide.webp'],
  ),
  DiscoveryCategoryConfig(
    id: 'lahmacun',
    titleKey: 'discoveryHomeCategoryLahmacun',
    searchTerm: 'lahmacun',
    imagePool: [
      'assets/images/categories/lahmacun.webp',
      'assets/images/categories/cigkofte.webp',
    ],
  ),
  DiscoveryCategoryConfig(
    id: 'burger',
    titleKey: 'discoveryHomeCategoryBurger',
    searchTerm: 'burger',
    imagePool: ['assets/images/categories/burger.webp'],
  ),
  DiscoveryCategoryConfig(
    id: 'pizza',
    titleKey: 'discoveryHomeCategoryPizza',
    searchTerm: 'pizza',
    imagePool: ['assets/images/categories/pizza.webp'],
  ),
  DiscoveryCategoryConfig(
    id: 'kebap',
    titleKey: 'discoveryHomeCategoryKebap',
    searchTerm: 'kebap',
    imagePool: ['assets/images/categories/kebap.webp'],
  ),
  DiscoveryCategoryConfig(
    id: 'corba',
    titleKey: 'discoveryHomeCategoryCorba',
    searchTerm: 'çorba',
    imagePool: ['assets/images/categories/corba.webp'],
  ),
  DiscoveryCategoryConfig(
    id: 'kahvalti',
    titleKey: 'discoveryHomeCategoryKahvalti',
    searchTerm: 'kahvaltı',
    imagePool: ['assets/images/categories/kahvalti-dish.webp'],
  ),
  DiscoveryCategoryConfig(
    id: 'manti',
    titleKey: 'discoveryHomeCategoryManti',
    searchTerm: 'mantı',
    imagePool: ['assets/images/categories/manti.webp'],
  ),
  DiscoveryCategoryConfig(
    id: 'tatli',
    titleKey: 'discoveryHomeCategoryTatli',
    searchTerm: 'tatlı',
    imagePool: ['assets/images/categories/tatli.webp'],
  ),
];
