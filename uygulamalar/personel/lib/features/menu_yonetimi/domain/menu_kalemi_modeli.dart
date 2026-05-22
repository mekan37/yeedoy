class MenuKalemi {
  final String id;
  final String ad;
  final String? kategori;
  final double? fiyat;
  final bool mevcut;
  final bool bugunSpesiyel;
  final int? stokSayisi; // null = stok takibi yok
  final String? gorselUrl; // P-10: ürün görseli

  const MenuKalemi({
    required this.id,
    required this.ad,
    this.kategori,
    this.fiyat,
    required this.mevcut,
    required this.bugunSpesiyel,
    this.stokSayisi,
    this.gorselUrl,
  });

  factory MenuKalemi.fromJson(Map<String, dynamic> j) {
    final section = j['menu_sections'];
    final sectionTitle = section is Map ? section['title'] as String? : null;
    final priceCents = j['price_cents'] as num?;
    return MenuKalemi(
      id: j['id'] as String,
      ad: j['name'] as String? ?? '?',
      kategori: j['category'] as String? ?? sectionTitle,
      fiyat: priceCents != null
          ? priceCents.toDouble() / 100
          : (j['price'] as num?)?.toDouble(),
      mevcut: j['is_available'] as bool? ?? true,
      bugunSpesiyel: j['is_today_special'] as bool? ?? false,
      stokSayisi: j['stock_count'] as int?,
      gorselUrl: j['image_url'] as String?,
    );
  }

  bool get stokTukendi => stokSayisi != null && stokSayisi! <= 0;
  bool get stokDusuk =>
      stokSayisi != null && stokSayisi! > 0 && stokSayisi! <= 5;

  MenuKalemi copyWith({
    String? kategori,
    bool? mevcut,
    bool? bugunSpesiyel,
    double? fiyat,
    int? stokSayisi,
    String? gorselUrl,
  }) => MenuKalemi(
    id: id,
    ad: ad,
    kategori: kategori ?? this.kategori,
    fiyat: fiyat ?? this.fiyat,
    mevcut: mevcut ?? this.mevcut,
    bugunSpesiyel: bugunSpesiyel ?? this.bugunSpesiyel,
    stokSayisi: stokSayisi ?? this.stokSayisi,
    gorselUrl: gorselUrl ?? this.gorselUrl,
  );
}
