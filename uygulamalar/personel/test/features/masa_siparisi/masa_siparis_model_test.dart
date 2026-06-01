import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy_personel/features/masa_siparisleri/domain/masa_siparisi_modeli.dart';

// Bu test dosyası masa_siparisi model sınıfını kapsar.
// kds/domain/ altındaki masa_siparisi_modeli_test.dart ile örtüşmemek için
// ek senaryolara ve edge-case'lere odaklanır.

void main() {
  group('MasaSiparisi — fromJson / round-trip', () {
    final testJson = {
      'id': 'abc-123',
      'table_number': '7',
      'status': 'pending',
      'items': [
        {'name': 'Adana Kebap', 'quantity': 2, 'note': 'Acısız'},
        {'item_name': 'Ayran', 'quantity': 1},
      ],
      'customer_note': 'Çabuk lütfen',
      'staff_note': 'VIP müşteri',
      'created_at': '2026-05-25T12:00:00.000Z',
    };

    test('temel alanlar dogru parse edilir', () {
      final model = MasaSiparisi.fromJson(testJson);
      expect(model.id, 'abc-123');
      expect(model.masaNo, '7');
      expect(model.durum, 'pending');
      expect(model.not, 'Çabuk lütfen');
      expect(model.personelNotu, 'VIP müşteri');
      expect(model.olusturuldu, DateTime.parse('2026-05-25T12:00:00.000Z'));
    });

    test('kalemler dogru parse edilir', () {
      final model = MasaSiparisi.fromJson(testJson);
      expect(model.kalemler.length, 2);
      expect(model.kalemler[0].urunAdi, 'Adana Kebap');
      expect(model.kalemler[0].adet, 2);
      expect(model.kalemler[0].not, 'Acısız');
      expect(model.kalemler[1].urunAdi, 'Ayran');
      expect(model.kalemler[1].adet, 1);
      expect(model.kalemler[1].not, isNull);
    });

    test('status enum — pending icin bekliyor false', () {
      final model = MasaSiparisi.fromJson(testJson);
      expect(model.bekliyor, isFalse);
    });

    test('status enum — waiting icin bekliyor true', () {
      final model = MasaSiparisi.fromJson({...testJson, 'status': 'waiting'});
      expect(model.bekliyor, isTrue);
    });

    test('status enum — done icin bekliyor false', () {
      final model = MasaSiparisi.fromJson({...testJson, 'status': 'done'});
      expect(model.bekliyor, isFalse);
    });

    test('items_json null oldugunda bos liste donuyor', () {
      final model = MasaSiparisi.fromJson({...testJson, 'items': null});
      expect(model.kalemler, isEmpty);
    });

    test('items bos liste oldugunda bos liste donuyor', () {
      final model = MasaSiparisi.fromJson({...testJson, 'items': <dynamic>[]});
      expect(model.kalemler, isEmpty);
    });

    test('customer_note null oldugunda not null', () {
      final model = MasaSiparisi.fromJson({...testJson, 'customer_note': null});
      expect(model.not, isNull);
    });
  });

  group('MasaSiparisi — copyWith', () {
    late MasaSiparisi base;

    setUp(() {
      base = MasaSiparisi(
        id: 'order-x',
        masaNo: '2',
        durum: 'pending',
        kalemler: const [SiparisKalem(urunAdi: 'Su', adet: 1)],
        olusturuldu: DateTime(2026, 5, 25),
      );
    });

    test('durum degistirilir, diger alanlar korunur', () {
      final guncellenmis = base.copyWith(durum: 'seen');
      expect(guncellenmis.durum, 'seen');
      expect(guncellenmis.id, base.id);
      expect(guncellenmis.masaNo, base.masaNo);
      expect(guncellenmis.kalemler.length, base.kalemler.length);
    });

    test('personelNotu eklenir', () {
      final guncellenmis = base.copyWith(personelNotu: 'Hemen hazırla');
      expect(guncellenmis.personelNotu, 'Hemen hazırla');
      expect(guncellenmis.durum, base.durum);
    });

    test('hicbir alan verilmezse ayni degerler korunur', () {
      final kopyasi = base.copyWith();
      expect(kopyasi.id, base.id);
      expect(kopyasi.durum, base.durum);
      expect(kopyasi.personelNotu, base.personelNotu);
    });
  });

  group('SiparisKalem — fromJson', () {
    test('name alani oncelikli', () {
      final kalem = SiparisKalem.fromJson({
        'name': 'Lahmacun',
        'item_name': 'Eski Ad',
        'quantity': 3,
      });
      expect(kalem.urunAdi, 'Lahmacun');
      expect(kalem.adet, 3);
    });

    test('item_name fallback kullanilir', () {
      final kalem = SiparisKalem.fromJson({'item_name': 'Salata', 'quantity': 2});
      expect(kalem.urunAdi, 'Salata');
    });

    test('her iki isim de yoksa soru isareti fallback', () {
      final kalem = SiparisKalem.fromJson({'quantity': 1});
      expect(kalem.urunAdi, '?');
    });

    test('quantity eksikse 1 varsayiliyor', () {
      final kalem = SiparisKalem.fromJson({'name': 'Ekmek'});
      expect(kalem.adet, 1);
    });

    test('quantity ondalikli sayiysa tam sayiya cevriliyor', () {
      final kalem = SiparisKalem.fromJson({'name': 'Çay', 'quantity': 2.0});
      expect(kalem.adet, 2);
    });

    test('note alani parse ediliyor', () {
      final kalem = SiparisKalem.fromJson({
        'name': 'Burger',
        'quantity': 1,
        'note': 'Sosssuz',
      });
      expect(kalem.not, 'Sosssuz');
    });
  });
}
