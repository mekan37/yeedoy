import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy_personel/features/masa_siparisleri/domain/masa_siparisi_modeli.dart';

void main() {
  group('MasaSiparisi.fromJson', () {
    final testJson = {
      'id': 'order-123',
      'table_number': '5',
      'status': 'pending',
      'items': [
        {'name': 'Köfte', 'quantity': 2, 'note': null},
        {'item_name': 'Ayran', 'quantity': 1},
      ],
      'customer_note': 'Az acılı',
      'staff_note': null,
      'created_at': '2026-05-25T10:00:00.000Z',
    };

    test('temel alanlar dogru parse edilir', () {
      final siparis = MasaSiparisi.fromJson(testJson);
      expect(siparis.id, 'order-123');
      expect(siparis.masaNo, '5');
      expect(siparis.durum, 'pending');
      expect(siparis.not, 'Az acılı');
      expect(siparis.kalemler.length, 2);
    });

    test('kalem alanları doğru parse edilir', () {
      final siparis = MasaSiparisi.fromJson(testJson);
      expect(siparis.kalemler[0].urunAdi, 'Köfte');
      expect(siparis.kalemler[0].adet, 2);
      expect(siparis.kalemler[1].urunAdi, 'Ayran');
      expect(siparis.kalemler[1].adet, 1);
    });

    test('bekliyor getter — waiting durumu icin true', () {
      final siparis = MasaSiparisi.fromJson({...testJson, 'status': 'waiting'});
      expect(siparis.bekliyor, isTrue);
    });

    test('bekliyor getter — pending durumu icin false', () {
      final siparis = MasaSiparisi.fromJson(testJson);
      expect(siparis.bekliyor, isFalse);
    });

    test('copyWith durum gunceller', () {
      final siparis = MasaSiparisi.fromJson(testJson);
      final guncellenmis = siparis.copyWith(durum: 'seen');
      expect(guncellenmis.durum, 'seen');
      expect(guncellenmis.id, siparis.id);
      expect(guncellenmis.masaNo, siparis.masaNo);
    });

    test('copyWith personelNotu gunceller', () {
      final siparis = MasaSiparisi.fromJson(testJson);
      final guncellenmis = siparis.copyWith(personelNotu: 'Hazırlanıyor');
      expect(guncellenmis.personelNotu, 'Hazırlanıyor');
      expect(guncellenmis.durum, siparis.durum);
    });

    test('items listesi bos olsa da parse calışır', () {
      final siparis = MasaSiparisi.fromJson({...testJson, 'items': null});
      expect(siparis.kalemler, isEmpty);
    });
  });

  group('SiparisKalem.fromJson', () {
    test('name alani oncelikli', () {
      final kalem = SiparisKalem.fromJson({'name': 'Pilav', 'item_name': 'Eski', 'quantity': 3});
      expect(kalem.urunAdi, 'Pilav');
      expect(kalem.adet, 3);
    });

    test('item_name fallback', () {
      final kalem = SiparisKalem.fromJson({'item_name': 'Salata', 'quantity': 1});
      expect(kalem.urunAdi, 'Salata');
    });

    test('eksik quantity 1 olarak yorumlanir', () {
      final kalem = SiparisKalem.fromJson({'name': 'Su'});
      expect(kalem.adet, 1);
    });
  });
}
