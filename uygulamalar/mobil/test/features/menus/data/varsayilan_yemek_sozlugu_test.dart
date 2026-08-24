import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy/features/menus/data/varsayilan_yemek_sozlugu.dart';

void main() {
  final kutuphane = [
    const StockDishImage(id: '1', imageUrl: 'https://x.test/corbalar/mercimek.webp', keywords: ['mercimek çorbası']),
    const StockDishImage(id: '2', imageUrl: 'https://x.test/sulu_yemekler/ali_nazik.webp', keywords: ['ali nazik']),
    const StockDishImage(id: '4', imageUrl: 'https://x.test/sulu_yemekler/bamya.webp', keywords: ['etli bamya']),
    const StockDishImage(id: '5', imageUrl: 'https://x.test/corbalar/bamya.webp', keywords: ['bamya çorbası']),
  ];

  group('VarsayilanYemekSozlugu.bul', () {
    test('urun adi bir anahtar ifadeyi iceriyorsa ilgili gorseli doner', () {
      expect(
        VarsayilanYemekSozlugu.bul('Mercimek Corbasi', kutuphane),
        'https://x.test/corbalar/mercimek.webp',
      );
    });

    test('bitisik yazilmis yemek adini da eslestirir (or. "Alinazik")', () {
      expect(
        VarsayilanYemekSozlugu.bul('Alinazik Kebap', kutuphane),
        'https://x.test/sulu_yemekler/ali_nazik.webp',
      );
    });

    test('ayni kelime birden fazla goselde geçerse en uzun/ozgul anahtar kazanir', () {
      expect(
        VarsayilanYemekSozlugu.bul('Etli Bamya Corbasi', kutuphane),
        'https://x.test/corbalar/bamya.webp',
      );
    });

    test('hicbir anahtar ifade eslesmiyorsa null doner', () {
      expect(VarsayilanYemekSozlugu.bul('Cheeseburger', kutuphane), isNull);
    });

    test('bos kutuphaneyle null doner (hata firlatmaz)', () {
      expect(VarsayilanYemekSozlugu.bul('Mercimek Corbasi', const []), isNull);
    });
  });

  group('StockDishImage.fromMap', () {
    test('gecerli map alanlarini dogru parse eder', () {
      final item = StockDishImage.fromMap({
        'id': '42',
        'image_url': 'https://x.test/a.webp',
        'keywords': ['a', 'b'],
      });
      expect(item.id, '42');
      expect(item.imageUrl, 'https://x.test/a.webp');
      expect(item.keywords, ['a', 'b']);
    });

    test('eksik keywords alaniyla bos listeye duser', () {
      final item = StockDishImage.fromMap({'id': '1', 'image_url': 'https://x.test/a.webp'});
      expect(item.keywords, isEmpty);
    });
  });
}
