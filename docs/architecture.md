# Mimari

## Monorepo Yapısı
- `apps/mobile_flutter`: Mobil tüketici uygulaması
- `apps/panel_flutter_web`: Owner/Admin panel uygulaması (Flutter Web)
- `apps/web_next`: Public web + QR menü (Next.js)
- `packages/*`: Ortak tip, config, token, l10n ve api yardımcıları
- `supabase/*`: Şema, politika, migration dosyaları
- `tools/*`: Veri import ve analiz scriptleri

## Ortak Backend
- Tüm uygulamalar aynı Supabase projesini kullanır.
- Ortam değişkenleri tüm uygulamalarda aynı isim standardıyla yönetilir.

## Ürünleştirme İlkeleri
- “Kullanılmıyor” görünen modül önce görünür hale getirilir.
- DevTools ekranları production’da kapalı tutulur.
- Temizlik/silme işlemleri `docs/cleanup_log.md` içinde kayıt altına alınır.
