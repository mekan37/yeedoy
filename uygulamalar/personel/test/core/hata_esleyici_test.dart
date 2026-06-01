import 'package:flutter_test/flutter_test.dart';
import 'package:yeedoy_personel/core/hata_esleyici.dart';

void main() {
  group('HataEsleyici.mesaj', () {
    test('ag hatasi — network exception', () {
      final msg = HataEsleyici.mesaj(Exception('SocketException: network error'));
      expect(msg, contains('İnternet'));
    });

    test('ag hatasi — timeout', () {
      final msg = HataEsleyici.mesaj(Exception('timeout after 30s'));
      expect(msg, contains('İnternet'));
    });

    test('kimlik hatasi — invalid credentials', () {
      final msg = HataEsleyici.mesaj(Exception('invalid login credentials'));
      expect(msg, contains('E-posta veya şifre'));
    });

    test('kimlik hatasi — jwt expired', () {
      final msg = HataEsleyici.mesaj(Exception('JWT expired'));
      expect(msg, contains('Oturum'));
    });

    test('yetki hatasi — permission denied', () {
      final msg = HataEsleyici.mesaj(Exception('permission denied for table orders'));
      expect(msg, contains('yetkiniz'));
    });

    test('veritabani — unique violation', () {
      final msg = HataEsleyici.mesaj(Exception('23505 unique violation'));
      expect(msg, contains('zaten mevcut'));
    });

    test('sunucu hatasi — 500', () {
      final msg = HataEsleyici.mesaj(Exception('500 internal server error'));
      expect(msg, contains('Sunucu'));
    });

    test('bilinmeyen hata — ham mesaj gosterilmemeli', () {
      final msg = HataEsleyici.mesaj(Exception('some internal detail: stack trace line 42'));
      // Ham exception detayı UI'a sızdırılmamalı
      expect(msg, isNot(contains('stack trace')));
      expect(msg, isNot(contains('line 42')));
      expect(msg.length, greaterThan(10));
    });

    test('rate limit hatasi', () {
      final msg = HataEsleyici.mesaj(Exception('429 too many requests'));
      expect(msg, contains('bekleyin'));
    });
  });
}
