import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yeedoy/core/errors/app_error_mapper.dart';

// B43 (mimari denetim): AppErrorMapper — 0 test kapsamıydı, B22'nin en ucuz
// önleyici testiydi (mapper'ın kendisi zaten düzeltilmişti, regresyon
// testi hiç yazılmamıştı). Kod hataya göre kullanıcıya gösterilecek Türkçe
// mesajı seçtiği için — yanlış bir eşleme, kullanıcının ham İngilizce/teknik
// hata görmesi veya yanlış yönlendirilmesi anlamına gelir.
void main() {
  group('AppErrorMapper.message', () {
    test('null hata için genel mesaj döner', () {
      expect(AppErrorMapper.message(null), 'Bir hata oluştu.');
    });

    test('AuthException mesajını olduğu gibi döner', () {
      final error = AuthException('Geçersiz kimlik bilgileri');
      expect(AppErrorMapper.message(error), 'Geçersiz kimlik bilgileri');
    });

    test('boş mesajlı AuthException için varsayılan giriş mesajı döner', () {
      final error = AuthException('');
      expect(AppErrorMapper.message(error), 'Giriş gerekli.');
    });

    test('PostgrestException mesajını olduğu gibi döner', () {
      final error = PostgrestException(message: 'duplicate key value');
      expect(AppErrorMapper.message(error), 'duplicate key value');
    });

    test('boş mesajlı PostgrestException için genel işlem mesajı döner', () {
      final error = PostgrestException(message: '');
      expect(
        AppErrorMapper.message(error),
        'İşlem sırasında bir hata oluştu.',
      );
    });

    test(
      'LocationServiceDisabledException için GPS-kapalı mesajı döner (B22)',
      () {
        expect(
          AppErrorMapper.message(const LocationServiceDisabledException()),
          contains('Konum servisleri kapalı'),
        );
      },
    );

    test('PermissionDeniedException için konum izni mesajı döner', () {
      expect(
        AppErrorMapper.message(const PermissionDeniedException('denied')),
        'Konum izni gerekli.',
      );
    });

    test(
      'ham SocketException benzeri metinler için Türkçe bağlantı mesajı döner (B22)',
      () {
        final error = Exception('SocketException: Failed host lookup');
        expect(
          AppErrorMapper.message(error),
          contains('İnternet bağlantısı yok veya zayıf'),
        );
      },
    );

    test('timeout metni için de bağlantı mesajı döner (B22)', () {
      final error = Exception('Connection timed out after 30s');
      expect(
        AppErrorMapper.message(error),
        contains('İnternet bağlantısı yok veya zayıf'),
      );
    });

    test('bilinen hata kodu içeren Exception için eşlenmiş mesaj döner', () {
      final error = Exception('rate_limited_user');
      expect(
        AppErrorMapper.message(error),
        'Çok sık deneme algılandı. Lütfen biraz sonra tekrar dene.',
      );
    });

    test('review_daily_rate_limited için günlük limit mesajı döner', () {
      final error = Exception('review_daily_rate_limited');
      expect(
        AppErrorMapper.message(error),
        'Günlük limit doldu. Daha sonra tekrar dene.',
      );
    });

    test('eşlenmemiş Exception mesajını ham haliyle döner', () {
      final error = Exception('completely_unmapped_error_code');
      expect(AppErrorMapper.message(error), 'completely_unmapped_error_code');
    });

    test('Exception olmayan bilinmeyen bir hata için genel mesaj döner', () {
      expect(AppErrorMapper.message(Object()), 'Bir hata oluştu.');
    });
  });
}
