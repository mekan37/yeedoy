import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy_personel/features/kimlik/domain/kimlik_durum.dart';

// Minimal User stub — Supabase User requires full constructor; use factory pattern
// We test the sealed class hierarchy, not the Supabase User object itself.

void main() {
  group('KimlikDurum sealed class', () {
    test('KimlikGirilmemis olusturulabilir', () {
      const durum = KimlikGirilmemis();
      expect(durum, isA<KimlikDurum>());
      expect(durum, isA<KimlikGirilmemis>());
    });

    test('KimlikYukleniyor olusturulabilir', () {
      const durum = KimlikYukleniyor();
      expect(durum, isA<KimlikDurum>());
    });

    test('KimlikYetkisiz varsayilan mesaj null', () {
      const durum = KimlikYetkisiz();
      expect(durum.mesaj, isNull);
    });

    test('KimlikYetkisiz ozel mesaj tasiyabilir', () {
      const durum = KimlikYetkisiz(mesaj: 'Onaylı işletme kaydı gerekli');
      expect(durum.mesaj, contains('Onaylı'));
    });

    test('sealed class pattern matching calısır', () {
      const KimlikDurum durum = KimlikGirilmemis();
      final sonuc = switch (durum) {
        KimlikGirilmemis() => 'girilmemis',
        KimlikYukleniyor() => 'yukleniyor',
        KimlikDogrulaniyor() => 'dogrulaniyor',
        KimlikYetkisiz() => 'yetkisiz',
        KimlikGirilmis() => 'girilmis',
      };
      expect(sonuc, 'girilmemis');
    });
  });
}
