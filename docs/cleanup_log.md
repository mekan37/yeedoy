# Doküman Temizlik ve Konsolidasyon Kaydı

## 2026-02-26 (Önceki Kayıtlar)

- `apps/web_next/.env.example`
  - Sebep: Standart dışı/güvensiz örnek içerik notu.
  - İşlem: Dosya aynı yolda yeniden düzenlendi.

- `apps/web_next/README.md`
  - Sebep: Monorepo yapısıyla uyumsuz eski anlatım.
  - İşlem: Aynı yolda yeniden yazım.

- Kökte geçici analiz dosyaları (`.txt/.md`)
  - Sebep: Kalıcı ürün dokümanı olmamaları.
  - İşlem: Kaldırıldı, kalıcı içerik `docs/*` altında tutuldu.

## 2026-02-27

- `docs/product.md`
  - İşlem: Yeni oluşturuldu.
  - Amaç: Ürünün gerçek kapsamını kod kanıtlarıyla tanımlamak.

- `docs/apps.md`
  - İşlem: Yeni oluşturuldu.
  - Amaç: Uygulama envanteri, sorumluluklar, kısmi/bağlı olmayan modüller.

- `docs/architecture.md`
  - İşlem: Tamamen güncellendi (kaynak doküman formatı).
  - Amaç: Gerçek istemci-backend mimarisini ve yetki akışını netleştirmek.

- `docs/data-model.md`
  - İşlem: Yeni oluşturuldu.
  - Amaç: Migration + uygulama sorgularına dayalı veri modeli dökümü.

- `docs/qr-system.md`
  - İşlem: Yeni oluşturuldu.
  - Amaç: QR üretim/yönlendirme/render akışını gerçek implementasyondan belgelemek.

- `docs/setup.md`
  - İşlem: Tamamen güncellendi (kaynak doküman formatı).
  - Amaç: Kurulum/çalıştırma komutlarını gerçek scriptlerle eşlemek.

- `docs/cleanup_log.md`
  - İşlem: Yapılandırıldı ve önceki kayıtlar korunarak yeniden düzenlendi.

Not:

- Bu turda repo içinden kalıcı `.md/.txt` silinmedi; ana iş doküman konsolidasyonudur.

## 2026-02-27 (Devam)

- `docs/cleanup_decision_matrix.md`
  - İşlem: Yeni oluşturuldu.
  - Amaç: `qr_menu_next`, `web_order`, `packages/shared` gibi adaylar için sil/koru kararını kanıta bağlamak.

- `docs/security_env_cleanup_plan.md`
  - İşlem: Yeni oluşturuldu.
  - Amaç: `.env.example` güvenlik temizliği ve push sonrası secret rotasyon planını netleştirmek.

- `apps/mobile_flutter/.env.example`
  - İşlem: Gerçek anahtarlar kaldırıldı, placeholder'a çevrildi.
  - Ek: `SSUPABASE_URL` yazım hatası `SUPABASE_URL` olarak düzeltildi.

- `apps/web_next/.env.example`
  - İşlem: Gerçek anahtarlar kaldırıldı, placeholder'a çevrildi.
  - Ek: `NEXT_PUBLIC_*` değişkenleri placeholder üzerinden türetilecek şekilde korundu.
