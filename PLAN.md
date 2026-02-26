# Monorepo Ürünleştirme Planı

## 1) Envanter Özeti
- `apps/mobile_flutter`: Flutter mobil tüketici uygulaması.
- `apps/panel_flutter_web`: Flutter Web owner/admin paneli (aktif çalışan panel).
- `apps/web_next`: Next.js public web + QR menü + dashboard.
- `packages/shared`: eski ortak TS dosyaları.
- `docs`: dağınık dokümanlar.
- `tools`: import/scan/migrate scriptleri.

## 2) Kısıtlar
- Hedefte panelin Next.js olması isteniyor; mevcut çalışan panel Flutter Web.
- Servisi kesmemek için geçiş kademeli yapılmalı:
1. Flutter panel çalışmaya devam eder.
2. Ortak sözleşme ve monorepo standardı kurulur.
3. Admin ekranları kontrollü şekilde Next.js’e taşınır.

## 3) Modül Kararları (KULLAN / TAMAMLA / SİL)
- `KULLAN`:
  - `core/quality/release_gate.dart`, `core/quality/golden_paths.dart`
  - `core/monitoring/*`
  - `suggestions`, `suspended_meals`, `taste_twin`, `group_requests`
- `TAMAMLA`:
  - Mobil diagnostics/devtools görünürlüğü
  - Web `/devtools` ortam doğrulama
  - `docs/*` standart set
  - `packages/*` ortak iskelet
- `SİL`:
  - Önce görünürlük/entegrasyon tamamlanır
  - Silme oranı `%10` üstüne çıkmaz

## 4) UI Giriş Noktaları
- Mobil: `/dev-tools` (flag + debug gate)
- Web: `/devtools` (dev-only)
- Panel: `/admin/dev-tools` (dev-only)

## 5) Fazlar
1. Workspace + env standardı + app README
2. Ortak paket iskeletleri
3. Devtools ve görünürlük
4. Doküman konsolidasyonu
5. Doğrulama ve kontrollü temizlik

## 6) Silme Politikası
- İlk fazda agresif silme yok.
- Her silme `docs/cleanup_log.md` içine yol + sebep + karşılık dosya ile yazılır.
