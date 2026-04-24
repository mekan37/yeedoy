# ADR-0005: Panel Flutter Web Crash Monitoring (Sentry)

**Durum:** Kabul edildi  
**Tarih:** 2026-04-22  
**Karar verenler:** Geliştirme ekibi

## Bağlam

Mobile uygulamada Firebase Crashlytics aktif ve `setCustomKey(error_taxonomy, error_source)` ile zenginleştirilmiş. Panel Flutter Web'de crash monitoring yoktu; hatalar yalnızca browser console'da görünüyordu.

## Değerlendirilen Alternatifler

1. **Sentry Flutter SDK** — Flutter web'i destekleyen, DSN env değişkeninden alınan, PII scrubbing.
2. **Firebase Crashlytics** — Mobile'da zaten var ama Flutter Web desteği kısıtlı (experimentel).
3. **Logflare / Custom telemetry** — Mevcut `AppTelemetry` altyapısını web için genişletmek.

## Karar

**Seçenek 1**: `sentry_flutter` paketi. DSN `--dart-define=SENTRY_DSN=...` veya `.env` aracılığıyla aktarılır. `bootstrapWebApp()` içinde init edilir.

## Konfigürasyon Gereksinimleri

```dart
// bootstrap içinde:
await SentryFlutter.init(
  (options) {
    options.dsn = dsn; // env'den
    options.environment = isProd ? 'production' : 'staging';
    options.tracesSampleRate = 0.2; // %20 transaction
    options.beforeSend = _scrubPii;
  },
  appRunner: () => runApp(ProviderScope(child: app)),
);
```

**PII scrub kuralı:** `user.email`, `user.username`, `user.ip_address` Sentry'ye gönderilmez. Sadece Supabase `user.id` (UUID) ve `role` tagı eklenir.

## Sonuçlar

**Olumlu:** Panel hataları production'da izlenebilir hale gelir; owner ve admin hata raporları ayrı tag ile ayrışır.  
**Olumsuz:** DSN yönetimi için CI secret eklenmesi gerekir. `sentry_flutter` build boyutu +~200KB WASM (kabul edilebilir).
