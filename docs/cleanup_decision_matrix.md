# Temizlik Karar Matrisi (Sil/Koru)

Bu matris yalnızca mevcut kod bağlantısı ve kullanım kanıtına göre hazırlanmıştır.

## Adaylar

| Yol | Mevcut Durum | Kod Bağlantısı | Karar | Gerekçe |
|---|---|---|---|---|
| `qr_menu_next/` | Sadece `.next` ve `node_modules` artifact içeriyor | Uygulama/workspace referansı yok | **Sil** | Kaynak kod değil, eski build kalıntısı. |
| `apps/panel_flutter_web/lib/web_order/` | Route sabiti + TODO metinli placeholder app | `main_web_order.dart` var ama kök scriptlerde kullanılmıyor | **Koru (şimdilik)** | Gelecek modül için iskelet; hemen silmek yerine backlog'da tamamla/sadeleştir kararı verilmeli. |
| `packages/shared/` | Schema/type dosyaları var, `package.json` yok | Uygulama importlarında `@yeedoy/shared` kullanılmıyor | **Koru (inceleme sonrası)** | İçerik faydalı olabilir; önce `shared_types/shared_config` ile birleştirme planı çıkarılmalı. |
| `deploy/admin` ve `deploy/owner` içindeki `karaliste.txt` kopyaları | Build çıktısı içinde tekrar ediyor | Çalışma anında build artifacti | **Koru** | Deploy çıktısının parçası; kaynak tekilleştirme build pipeline seviyesinde yapılmalı. |

## Kanıtlar

- `qr_menu_next/` envanteri: yalnızca `.next` ve `node_modules`
- Panel web order placeholder:
  - `apps/panel_flutter_web/lib/web_order/web_order_app.dart`
  - `apps/panel_flutter_web/lib/main_web_order.dart`
  - `apps/panel_flutter_web/package.json`
- Paket kullanım taraması:
  - `@yeedoy/*` import eşleşmesi bulunamadı
  - `packages/shared` altında `package.json` bulunmuyor

## Uygulama Sırası Önerisi

1. `qr_menu_next/` klasörünü ayrı commit ile kaldır.
2. `web_order` için karar ver:
   - Tamamla (gerçek route/sayfalar), veya
   - Arşive al ve aktif app yüzeyinden çıkar.
3. `packages/shared` için konsolidasyon:
   - `shared_types`/`shared_config` ile net sorumluluk ayrımı,
   - Kullanılmayan dosyaları taşı/sil.
