class MasaSiparisi {
  final String id;
  final String masaNo;
  final String durum; // 'pending' | 'seen' | 'waiting' | 'done'
  final List<SiparisKalemi> kalemler;
  final String? not; // müşteri notu
  final String? personelNotu; // P-6: personel dahili notu
  final DateTime olusturuldu;

  const MasaSiparisi({
    required this.id,
    required this.masaNo,
    required this.durum,
    required this.kalemler,
    this.not,
    this.personelNotu,
    required this.olusturuldu,
  });

  factory MasaSiparisi.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'] as List<dynamic>? ?? [];
    return MasaSiparisi(
      id: j['id'] as String,
      masaNo: j['table_number'] as String? ?? '?',
      durum: j['status'] as String? ?? 'pending',
      kalemler: rawItems
          .map((e) => SiparisKalem.fromJson(e as Map<String, dynamic>))
          .toList(),
      not: j['customer_note'] as String?,
      personelNotu: j['staff_note'] as String?,
      olusturuldu: DateTime.parse(j['created_at'] as String),
    );
  }

  bool get bekliyor => durum == 'waiting';

  MasaSiparisi copyWith({String? durum, String? personelNotu}) => MasaSiparisi(
        id: id,
        masaNo: masaNo,
        durum: durum ?? this.durum,
        kalemler: kalemler,
        not: not,
        personelNotu: personelNotu ?? this.personelNotu,
        olusturuldu: olusturuldu,
      );
}

class SiparisKalem {
  final String urunAdi;
  final int adet;
  final String? not;

  const SiparisKalem({
    required this.urunAdi,
    required this.adet,
    this.not,
  });

  factory SiparisKalem.fromJson(Map<String, dynamic> j) => SiparisKalem(
        urunAdi: j['name'] as String? ?? j['item_name'] as String? ?? '?',
        adet: (j['quantity'] as num?)?.toInt() ?? 1,
        not: j['note'] as String?,
      );
}

// Alias
typedef SiparisKalemi = SiparisKalem;
