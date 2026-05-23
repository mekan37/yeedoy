enum ModerasayonDurum { bekliyor, temiz, kaldirildi }

class IsletmeYorum {
  final String id;
  final int puan;
  final String? icerik;
  final DateTime olusturuldu;
  final String? yazarAdi;
  final String? sahipYaniti;
  final DateTime? sahipYanitiTarihi;
  final bool sikayet;
  final ModerasayonDurum moderasyonDurum;

  const IsletmeYorum({
    required this.id,
    required this.puan,
    this.icerik,
    required this.olusturuldu,
    this.yazarAdi,
    this.sahipYaniti,
    this.sahipYanitiTarihi,
    this.sikayet = false,
    this.moderasyonDurum = ModerasayonDurum.temiz,
  });

  factory IsletmeYorum.fromJson(Map<String, dynamic> j) {
    final mod = j['moderation_status'] as String? ?? 'clean';
    return IsletmeYorum(
      id: j['id'] as String,
      puan: (j['rating'] as num?)?.toInt() ?? 0,
      icerik: j['content'] as String?,
      olusturuldu: DateTime.parse(j['created_at'] as String),
      yazarAdi:
          (j['profiles'] as Map<String, dynamic>?)?['display_name'] as String?,
      sahipYaniti: j['owner_reply'] as String?,
      sahipYanitiTarihi: j['owner_replied_at'] != null
          ? DateTime.parse(j['owner_replied_at'] as String)
          : null,
      sikayet: j['has_flag'] as bool? ?? false,
      moderasyonDurum: mod == 'removed'
          ? ModerasayonDurum.kaldirildi
          : mod == 'pending'
              ? ModerasayonDurum.bekliyor
              : ModerasayonDurum.temiz,
    );
  }

  IsletmeYorum withYanit(String yanit) => IsletmeYorum(
        id: id,
        puan: puan,
        icerik: icerik,
        olusturuldu: olusturuldu,
        yazarAdi: yazarAdi,
        sahipYaniti: yanit,
        sahipYanitiTarihi: DateTime.now(),
      );

  IsletmeYorum withoutYanit() => IsletmeYorum(
        id: id,
        puan: puan,
        icerik: icerik,
        olusturuldu: olusturuldu,
        yazarAdi: yazarAdi,
        sahipYaniti: null,
        sahipYanitiTarihi: null,
      );
}
