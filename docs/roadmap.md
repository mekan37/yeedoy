# Yol Haritası (Koddan Çıkan Durum)

Bu doküman "plan/niyet" değil, mevcut koddan görülen açık başlıkları listeler.

## Tamamlanmış Görünenler

- 3 uygulamalı monorepo yapısı (`mobile_flutter`, `panel_flutter_web`, `web_next`)
- QR üretim + public menü render akışı (Next)
- Owner/Admin ana route omurgası (panel Flutter)
- Mobilde keşif/işletme/menü/topluluk çekirdeği

## Devam Eden / Kısmi Kalanlar

- Next `/admin` sayfası placeholder durumda.
- Next `/owner` ve `/menu-builder` route'ları redirect düzeyinde.
- Panelde `web_order` uygulaması TODO içeriyor.
- Web test pipeline'da gerçek test dosyası bulunmuyor (smoke = lint + typecheck).

## Teknik Borç Başlıkları

- L10n dosyalarında mojibake/encoding izleri.
- Bazı dokümanlarda eski plan dili ve güncel kod arasında farklar.
- PowerShell odaklı kök scriptlerin cross-platform karşılığı sınırlı.

## Referans Kaynaklar

- `docs/product.md`
- `docs/apps.md`
- `docs/architecture.md`
- `docs/data-model.md`
- `docs/module_visibility_matrix.md`
