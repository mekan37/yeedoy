/// Supabase ve genel hataları kullanıcı dostu Türkçe mesajlara çevirir.
class HataEsleyici {
  const HataEsleyici._();

  static String mesaj(Object e) {
    final raw = e.toString().toLowerCase();

    // Ağ hataları
    if (raw.contains('network') || raw.contains('socketexception') ||
        raw.contains('connection') || raw.contains('timeout')) {
      return 'İnternet bağlantısı yok. Bağlantınızı kontrol edin.';
    }

    // Supabase kimlik doğrulama hataları
    if (raw.contains('invalid login credentials') ||
        raw.contains('invalid_credentials') ||
        raw.contains('wrong password')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (raw.contains('email not confirmed') ||
        raw.contains('email_not_confirmed')) {
      return 'E-posta adresiniz henüz doğrulanmamış.';
    }
    if (raw.contains('user not found') || raw.contains('no user found')) {
      return 'Bu e-posta ile kayıtlı hesap bulunamadı.';
    }
    if (raw.contains('too many requests') || raw.contains('rate limit') ||
        raw.contains('429')) {
      return 'Çok fazla deneme yapıldı. Lütfen bir süre bekleyin.';
    }
    if (raw.contains('jwt expired') || raw.contains('session_not_found') ||
        raw.contains('token is expired')) {
      return 'Oturum süreniz doldu. Lütfen tekrar giriş yapın.';
    }
    if (raw.contains('user already registered') ||
        raw.contains('email already exists')) {
      return 'Bu e-posta adresi zaten kayıtlı.';
    }

    // Supabase veritabanı hataları
    if (raw.contains('23505') || raw.contains('unique violation') ||
        raw.contains('duplicate key')) {
      return 'Bu kayıt zaten mevcut.';
    }
    if (raw.contains('23503') || raw.contains('foreign key violation')) {
      return 'Bu kayıt silinemez; başka kayıtlarla ilişkili.';
    }
    if (raw.contains('42501') || raw.contains('permission denied') ||
        raw.contains('insufficient_privilege')) {
      return 'Bu işlem için yetkiniz bulunmuyor.';
    }
    if (raw.contains('pgrst116') || raw.contains('0 rows')) {
      return 'İstenen kayıt bulunamadı.';
    }

    // Genel sunucu hatası
    if (raw.contains('500') || raw.contains('internal server error') ||
        raw.contains('server error')) {
      return 'Sunucu hatası oluştu. Lütfen tekrar deneyin.';
    }
    if (raw.contains('503') || raw.contains('service unavailable')) {
      return 'Servis geçici olarak kullanılamıyor.';
    }

    // Bilinmeyen hata — ham mesajı gösterme, genel bir mesaj ver
    return 'Beklenmedik bir hata oluştu. Lütfen tekrar deneyin.';
  }
}
