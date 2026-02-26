import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_error_codes.dart';

class AppErrorMapper {
  static String message(Object? error) {
    if (error == null) return 'Bir hata oluştu.';

    if (error is AuthException) {
      return error.message.isEmpty ? 'Giriş gerekli.' : error.message;
    }

    if (error is PostgrestException) {
      if (error.message.isNotEmpty) return error.message;
      return 'İşlem sırasında bir hata oluştu.';
    }

    if (error is Exception) {
      final text = error.toString();
      const prefix = 'Exception: ';
      if (text.startsWith(prefix)) {
        final raw = text.substring(prefix.length).trim();
        final mapped = _mapError(raw);
        return mapped ?? raw;
      }
      final mapped = _mapError(text);
      return mapped ?? text;
    }

    return 'Bir hata oluştu.';
  }

  static String? _mapError(String raw) {
    if (raw.contains(AppErrorCodes.containsLinkOrPhone)) {
      return 'Link veya telefon bilgisi paylaşamazsın.';
    }
    if (raw.contains(AppErrorCodes.containsProfanity)) {
      return 'Uygunsuz içerik tespit edildi.';
    }
    if (raw.contains(AppErrorCodes.emojiSpam)) {
      return 'Çok fazla emoji kullanımı tespit edildi.';
    }
    if (raw.contains(AppErrorCodes.reviewDailyRateLimited) ||
        raw.contains('rate_limited_daily')) {
      return 'Günlük limit doldu. Daha sonra tekrar dene.';
    }
    if (raw.contains(AppErrorCodes.priceSuggestionDailyRateLimited)) {
      return 'Günlük fiyat öneri limiti doldu.';
    }
    if (raw.contains(AppErrorCodes.priceSuggestionSameItemCooldown)) {
      return 'Aynı ürün için kısa sürede tekrar öneri veremezsin.';
    }
    if (raw.contains(AppErrorCodes.menuPhotoDailyRateLimited) ||
        raw.contains(AppErrorCodes.businessMediaDailyRateLimited)) {
      return 'Günlük fotoğraf yükleme limiti doldu.';
    }
    if (raw.contains(AppErrorCodes.rateLimitedUser) ||
        raw.contains(AppErrorCodes.rateLimitedIp) ||
        raw.contains(AppErrorCodes.rateLimitedScope)) {
      return 'Çok sık deneme algılandı. Lütfen biraz sonra tekrar dene.';
    }
    if (raw.contains(AppErrorCodes.softRateLimited)) {
      return 'Güvenlik nedeniyle geçici yavaşlatma aktif. Biraz sonra tekrar dene.';
    }
    if (raw.contains(AppErrorCodes.reasonRequired)) {
      return 'Admin işlemleri için neden girmen zorunlu.';
    }
    if (raw.contains(AppErrorCodes.photoSizeLimitExceeded)) {
      return 'Dosya boyutu limiti aşıldı.';
    }
    if (raw.contains(AppErrorCodes.unsupportedImageType)) {
      return 'Sadece JPG, PNG veya WEBP yükleyebilirsin.';
    }
    if (raw.contains(AppErrorCodes.invalidImageData)) {
      return 'Geçersiz görsel dosyası.';
    }
    if (raw.contains(AppErrorCodes.imageDimensionsExceeded)) {
      return 'Görsel boyutu çok büyük.';
    }
    if (raw.contains(AppErrorCodes.storageUploadFailed)) {
      return 'Görsel depolama hatası. Lütfen tekrar dene.';
    }
    if (raw.contains(AppErrorCodes.edgeGuardRequired)) {
      return 'Güvenlik kontrolü nedeniyle işlem tekrar doğrulanmalı. Lütfen yeniden dene.';
    }
    if (raw.contains(AppErrorCodes.deniedIpReputation)) {
      return 'Güvenlik nedeniyle bu ağdan geçici olarak işlem kapatıldı.';
    }
    if (raw.contains(AppErrorCodes.shadowBanned)) {
      return 'İşlemin alındı, kontrol ediliyor.';
    }
    if (raw.contains(AppErrorCodes.offlineQueued)) {
      return 'Bağlantı zayıf. İşlem kuyruğa alındı, internet gelince otomatik gönderilecek.';
    }
    if (raw.contains(AppErrorCodes.contactVerificationRequired)) {
      return 'Bu işlem için e-posta veya telefon doğrulaması gerekli.';
    }
    return null;
  }
}
