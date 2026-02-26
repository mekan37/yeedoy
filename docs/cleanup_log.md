# Temizlik Kaydı

## 2026-02-26
- `apps/web_next/.env.example`
  - sebep: standart dışı ve güvenli olmayan örnek içerik
  - işlem: standart isimlerle yeniden oluşturuldu
  - karşılık: aynı yol

- `apps/web_next/README.md`
  - sebep: monorepo yapısına uymuyordu
  - işlem: Türkçe ve güncel formatta yeniden yazıldı
  - karşılık: aynı yol

- `c:/yeedoy` kökünde scan/report amaçlı geçici `.txt/.md` dosyaları
  - sebep: ürün dokümantasyonu değildi, geçici analiz çıktısıydı
  - işlem: kaldırıldı
  - karşılık: kalıcı dokümanlar `docs/*` altında tutuluyor
