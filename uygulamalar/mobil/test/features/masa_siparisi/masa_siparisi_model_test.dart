import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/masa_siparisi/domain/masa_siparisi_modeli.dart';
import 'package:yeedoy/features/masa_siparisi/domain/masa_siparisi_sepet_bildiricisi.dart';

// Doğrudan StateNotifier state'ini test etmek için erişilebilir alt sınıf.
// MasaSiparisiSepetBildiricisi'nin state özelliği StateNotifier üzerinden
// protected değildir — doğrudan erişilebilir.
class _TestableSepet extends MasaSiparisiSepetBildiricisi {}

void main() {
  group('MasaSiparisKalemi', () {
    test('copyWith adet gunceller', () {
      final kalem = MasaSiparisKalemi(
        menuItemId: 'item-1',
        name: 'Köfte',
        priceCents: 8500,
        adet: 1,
      );
      final guncellenmis = kalem.copyWith(adet: 3);
      expect(guncellenmis.adet, 3);
      expect(guncellenmis.menuItemId, kalem.menuItemId);
      expect(guncellenmis.priceCents, kalem.priceCents);
    });

    test('copyWith not gunceller', () {
      final kalem = MasaSiparisKalemi(
        menuItemId: 'item-1',
        name: 'Adana',
        priceCents: 12000,
      );
      final guncellenmis = kalem.copyWith(not: 'Acısız');
      expect(guncellenmis.not, 'Acısız');
      expect(guncellenmis.adet, kalem.adet);
    });

    test('varsayilan adet 1dir', () {
      final kalem = MasaSiparisKalemi(
        menuItemId: 'x',
        name: 'Su',
        priceCents: 500,
      );
      expect(kalem.adet, 1);
    });
  });

  group('MasaSiparisiOzet.fromMap', () {
    final testMap = {
      'id': 'order-789',
      'business_id': 'biz-456',
      'table_no': '12',
      'status': 'bekliyor',
      'created_at': '2026-05-25T15:30:00.000Z',
    };

    test('temel alanlar dogru parse edilir', () {
      final ozet = MasaSiparisiOzet.fromMap(testMap);
      expect(ozet.id, 'order-789');
      expect(ozet.businessId, 'biz-456');
      expect(ozet.tableNo, '12');
      expect(ozet.status, 'bekliyor');
    });

    test('created_at dogru parse edilir', () {
      final ozet = MasaSiparisiOzet.fromMap(testMap);
      expect(ozet.createdAt.year, 2026);
      expect(ozet.createdAt.month, 5);
      expect(ozet.createdAt.day, 25);
    });

    test('id null ise bos string fallback', () {
      final ozet = MasaSiparisiOzet.fromMap({...testMap, 'id': null});
      expect(ozet.id, '');
    });

    test('status null ise bekliyor fallback', () {
      final ozet = MasaSiparisiOzet.fromMap({...testMap, 'status': null});
      expect(ozet.status, 'bekliyor');
    });

    test('gecersiz created_at — DateTime.now fallback ile hata atmaz', () {
      // Geçersiz tarih için _asDate DateTime.now() fallback kullanıyor
      final ozet = MasaSiparisiOzet.fromMap({...testMap, 'created_at': 'INVALID'});
      expect(ozet.createdAt, isA<DateTime>());
    });
  });

  group('MasaSiparisiSepetBildiricisi', () {
    test('ekle — yeni kalem ekleniyor', () {
      final notifier = _TestableSepet();
      final kalem = MasaSiparisKalemi(
        menuItemId: 'item-1',
        name: 'Köfte',
        priceCents: 8500,
      );
      notifier.ekle(kalem);
      expect(notifier.state.length, 1);
      expect(notifier.state.first.menuItemId, 'item-1');
    });

    test('ekle — ayni kalem tekrar eklenince adet artar', () {
      final notifier = _TestableSepet();
      final kalem = MasaSiparisKalemi(
        menuItemId: 'item-1',
        name: 'Köfte',
        priceCents: 8500,
      );
      notifier.ekle(kalem);
      notifier.ekle(kalem);
      expect(notifier.state.length, 1);
      expect(notifier.state.first.adet, 2);
    });

    test('cikar — adet 1den fazlaysa azaltiyor', () {
      final notifier = _TestableSepet();
      final kalem = MasaSiparisKalemi(
        menuItemId: 'item-1',
        name: 'Köfte',
        priceCents: 8500,
        adet: 3,
      );
      notifier.ekle(kalem);
      notifier.ekle(kalem); // state: adet=4
      notifier.cikar('item-1');
      expect(notifier.state.first.adet, 3);
    });

    test('cikar — adet 1 ise kalem siliniyor', () {
      final notifier = _TestableSepet();
      final kalem = MasaSiparisKalemi(
        menuItemId: 'item-2',
        name: 'Su',
        priceCents: 500,
      );
      notifier.ekle(kalem);
      expect(notifier.state.length, 1);
      notifier.cikar('item-2');
      expect(notifier.state, isEmpty);
    });

    test('temizle — sepet bosaltiliyor', () {
      final notifier = _TestableSepet();
      notifier.ekle(MasaSiparisKalemi(menuItemId: 'a', name: 'A', priceCents: 100));
      notifier.ekle(MasaSiparisKalemi(menuItemId: 'b', name: 'B', priceCents: 200));
      notifier.temizle();
      expect(notifier.state, isEmpty);
    });

    test('toplamAdet dogru hesaplaniyor', () {
      final notifier = _TestableSepet();
      notifier.ekle(MasaSiparisKalemi(
          menuItemId: 'a', name: 'A', priceCents: 100, adet: 2));
      notifier.ekle(MasaSiparisKalemi(menuItemId: 'b', name: 'B', priceCents: 200));
      // a: ekle ile adet=2 eklendi → state'te adet=2
      // b: ekle ile adet=1 eklendi
      expect(notifier.toplamAdet, 3);
    });

    test('toplamFiyatCents dogru hesaplaniyor', () {
      final notifier = _TestableSepet();
      notifier.ekle(MasaSiparisKalemi(
          menuItemId: 'a', name: 'A', priceCents: 1000, adet: 2));
      notifier.ekle(MasaSiparisKalemi(menuItemId: 'b', name: 'B', priceCents: 500));
      // a: 2 * 1000 = 2000, b: 1 * 500 = 500 → toplam 2500
      expect(notifier.toplamFiyatCents, 2500);
    });
  });
}
