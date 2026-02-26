class DiscoveryCategoryConfig {
  const DiscoveryCategoryConfig({
    required this.id,
    required this.title,
    required this.searchTerm,
    required this.imagePool,
  });

  final String id;
  final String title;
  final String searchTerm;
  final List<String> imagePool;
}

const discoveryFilterLabels = <String>[
  'Kafe',
  'Restoran',
  'Tatlı / Pastane',
  'Kahvaltı',
  'Balık / Et',
  'Mekan',
];

const discoveryHomeCategories = <DiscoveryCategoryConfig>[
  DiscoveryCategoryConfig(
    id: 'doner',
    title: 'İnce Döner',
    searchTerm: 'döner',
    imagePool: [
      'assets/images/categories/doner.png',
      'assets/images/categories/tantuni.png',
    ],
  ),
  DiscoveryCategoryConfig(
    id: 'pide',
    title: 'Pide',
    searchTerm: 'pide',
    imagePool: ['assets/images/categories/pide.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'lahmacun',
    title: 'Lahmacun',
    searchTerm: 'lahmacun',
    imagePool: [
      'assets/images/categories/lahmacun.png',
      'assets/images/categories/cigkofte.png',
    ],
  ),
  DiscoveryCategoryConfig(
    id: 'burger',
    title: 'Burger',
    searchTerm: 'burger',
    imagePool: ['assets/images/categories/burger.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'pizza',
    title: 'Pizza',
    searchTerm: 'pizza',
    imagePool: ['assets/images/categories/pizza.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'kebap',
    title: 'Kebap',
    searchTerm: 'kebap',
    imagePool: ['assets/images/categories/kebap.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'corba',
    title: 'Çorba',
    searchTerm: 'çorba',
    imagePool: ['assets/images/categories/corba.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'kahvalti',
    title: 'Kahvaltı',
    searchTerm: 'kahvaltı',
    imagePool: ['assets/images/categories/kahvalti.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'manti',
    title: 'Mantı',
    searchTerm: 'mantı',
    imagePool: ['assets/images/categories/manti.png'],
  ),
  DiscoveryCategoryConfig(
    id: 'tatli',
    title: 'Tatlı',
    searchTerm: 'tatlı',
    imagePool: ['assets/images/categories/tatli.png'],
  ),
];

