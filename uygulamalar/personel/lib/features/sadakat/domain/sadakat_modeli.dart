enum LoyaltyTier { bronz, gumus, altin, platin }

extension LoyaltyTierX on LoyaltyTier {
  String get label => switch (this) {
    LoyaltyTier.bronz  => 'Bronz',
    LoyaltyTier.gumus  => 'Gümüş',
    LoyaltyTier.altin  => 'Altın',
    LoyaltyTier.platin => 'Platin',
  };

  // Bronze/Silver/Gold/Platinum foreground colours (simple)
  int get colorValue => switch (this) {
    LoyaltyTier.bronz  => 0xFFCD7F32,
    LoyaltyTier.gumus  => 0xFF9E9E9E,
    LoyaltyTier.altin  => 0xFFFFC107,
    LoyaltyTier.platin => 0xFF6C63FF,
  };

  static LoyaltyTier fromTotalStamps(int total) {
    if (total >= 100) return LoyaltyTier.platin;
    if (total >= 50)  return LoyaltyTier.altin;
    if (total >= 20)  return LoyaltyTier.gumus;
    return LoyaltyTier.bronz;
  }
}

class LoyaltyKart {
  final String id;
  final String kullaniciId;
  final String? kullaniciAdi;
  final String? telefon;
  final int stampSayisi;
  final int hedef;
  final int toplamStamp;

  const LoyaltyKart({
    required this.id,
    required this.kullaniciId,
    this.kullaniciAdi,
    this.telefon,
    required this.stampSayisi,
    required this.hedef,
    this.toplamStamp = 0,
  });

  factory LoyaltyKart.fromJson(Map<String, dynamic> j) => LoyaltyKart(
        id: j['id'] as String,
        kullaniciId: j['user_id'] as String,
        kullaniciAdi: j['user_name'] as String?,
        telefon: j['phone'] as String?,
        stampSayisi: (j['stamp_count'] as num?)?.toInt() ?? 0,
        hedef: (j['required_stamps'] as num?)?.toInt() ?? 10,
        toplamStamp: (j['total_stamps'] as num?)?.toInt() ?? 0,
      );

  double get ilerleme => hedef > 0 ? stampSayisi / hedef : 0;
  bool get tamamlandi => stampSayisi >= hedef;
  LoyaltyTier get tier => LoyaltyTierX.fromTotalStamps(toplamStamp);
}
