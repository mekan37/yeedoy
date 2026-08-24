import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yeedoy/features/menus/data/varsayilan_yemek_sozlugu.dart';

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString: 'SUPABASE_URL=https://test.supabase.co\nSUPABASE_ANON_KEY=test',
    );
  });

  group('VarsayilanYemekSozlugu.bul', () {
    test('kategori corba ise urun adina gore corba gorseli doner', () {
      final url = VarsayilanYemekSozlugu.bul('Mercimek Corbasi', 'Corbalar');
      expect(url, contains('varsayilan-yemekler/corbalar/mercimek.webp'));
    });

    test('bitisik yazilmis yemek adini da eslestirir (or. "Alinazik")', () {
      final url = VarsayilanYemekSozlugu.bul('Alinazik Kebap', 'Ana Yemekler');
      expect(url, contains('varsayilan-yemekler/sulu_yemekler/ali_nazik.webp'));
    });

    test('ayni slug birden fazla klasorde varsa kategoriye gore dogru klasoru secer', () {
      final zeytinyagli = VarsayilanYemekSozlugu.bul('Zeytinyagli Barbunya', 'Zeytinyaglilar');
      expect(zeytinyagli, contains('varsayilan-yemekler/zeytinyaglilar/barbunya.webp'));

      final suluYemek = VarsayilanYemekSozlugu.bul('Etli Bamya', 'Ana Yemekler');
      expect(suluYemek, contains('varsayilan-yemekler/sulu_yemekler/bamya.webp'));
    });

    test('kategori 4 kapsanan gruptan birine eslesmiyorsa null doner', () {
      expect(VarsayilanYemekSozlugu.bul('Cheeseburger', 'Burgerler'), isNull);
    });

    test('kategori kapsanan gruptaysa ama urun adi hicbir yemekle ortusmuyorsa null doner', () {
      expect(VarsayilanYemekSozlugu.bul('Bilinmeyen Ozel Yemek', 'Corbalar'), isNull);
    });

    test('kategori adi bos/yoksa null doner', () {
      expect(VarsayilanYemekSozlugu.bul('Mercimek Corbasi', null), isNull);
      expect(VarsayilanYemekSozlugu.bul('Mercimek Corbasi', ''), isNull);
    });

    test('donen URL Supabase Storage public path formatindadir', () {
      final url = VarsayilanYemekSozlugu.bul('Humus', 'Salata & Mezeler');
      expect(
        url,
        matches(
          RegExp(r'^https://.*/storage/v1/object/public/menu-media/varsayilan-yemekler/.*\.webp$'),
        ),
      );
    });
  });
}
