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
      'assets/images/categories/doner.png',
      'assets/images/categories/tantuni.png',
    ],
  ),
  DiscoveryCategoryConfig(
    id: 'pide',
    titleKey: 'discoveryHomeCategoryPide',
    searchTerm: 'pide',
    imagePool: ['assets/images/categories/pide.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'lahmacun',
    titleKey: 'discoveryHomeCategoryLahmacun',
    searchTerm: 'lahmacun',
    imagePool: [
      'assets/images/categories/lahmacun.png',
      'assets/images/categories/cigkofte.png',
    ],
  ),
  DiscoveryCategoryConfig(
    id: 'burger',
    titleKey: 'discoveryHomeCategoryBurger',
    searchTerm: 'burger',
    imagePool: ['assets/images/categories/burger.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'pizza',
    titleKey: 'discoveryHomeCategoryPizza',
    searchTerm: 'pizza',
    imagePool: ['assets/images/categories/pizza.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'kebap',
    titleKey: 'discoveryHomeCategoryKebap',
    searchTerm: 'kebap',
    imagePool: ['assets/images/categories/kebap.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'corba',
    titleKey: 'discoveryHomeCategoryCorba',
    searchTerm: 'çorba',
    imagePool: ['assets/images/categories/corba.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'kahvalti',
    titleKey: 'discoveryHomeCategoryKahvalti',
    searchTerm: 'kahvaltı',
    imagePool: ['assets/images/categories/kahvalti.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'manti',
    titleKey: 'discoveryHomeCategoryManti',
    searchTerm: 'mantı',
    imagePool: ['assets/images/categories/manti.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'tatli',
    titleKey: 'discoveryHomeCategoryTatli',
    searchTerm: 'tatlı',
    imagePool: ['assets/images/categories/tatli.png'],
  ),
];
